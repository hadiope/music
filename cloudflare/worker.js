// Cloudflare Worker — Iranian Sedà Telegram Bot (v6)
// Features: genre selection, channel forced-join, anonymous persists,
// admin notify on approve/reject, delete from bot, admin messaging,
// channel announce with custom text.
let BOT, SUPABASE_URL, SUPABASE_KEY, ADMIN_ID, CHANNEL_ID;

// --- helpers ---
const tg = (method, body) =>
  fetch(`https://api.telegram.org/bot${BOT}/${method}`, {
    method: 'POST',
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify(body),
  });

const sbSelect = (table, query = '') =>
  fetch(`${SUPABASE_URL}/rest/v1/${table}?${query}`, {
    headers: { apikey: SUPABASE_KEY, Authorization: `Bearer ${SUPABASE_KEY}` },
  }).then((r) => r.json());

const sbInsert = (table, row) =>
  fetch(`${SUPABASE_URL}/rest/v1/${table}`, {
    method: 'POST',
    headers: { apikey: SUPABASE_KEY, Authorization: `Bearer ${SUPABASE_KEY}`, 'Content-Type': 'application/json', Prefer: 'return=representation' },
    body: JSON.stringify(row),
  }).then((r) => r.json());

const sbUpdate = (table, query, patch) =>
  fetch(`${SUPABASE_URL}/rest/v1/${table}?${query}`, {
    method: 'PATCH',
    headers: { apikey: SUPABASE_KEY, Authorization: `Bearer ${SUPABASE_KEY}`, 'Content-Type': 'application/json' },
    body: JSON.stringify(patch),
  });

const sbDelete = (table, query) =>
  fetch(`${SUPABASE_URL}/rest/v1/${table}?${query}`, {
    method: 'DELETE',
    headers: { apikey: SUPABASE_KEY, Authorization: `Bearer ${SUPABASE_KEY}` },
  });

const sbUpload = async (bucket, path, bytes, type) =>
  fetch(`${SUPABASE_URL}/storage/v1/object/${bucket}/${path}`, {
    method: 'PUT',
    headers: { apikey: SUPABASE_KEY, Authorization: `Bearer ${SUPABASE_KEY}`, 'Content-Type': type || 'application/octet-stream' },
    body: bytes,
  });

const getFileUrl = (fileId) =>
  fetch(`https://api.telegram.org/bot${BOT}/getFile?file_id=${fileId}`)
    .then((r) => r.json())
    .then((j) => (j.ok ? `https://api.telegram.org/file/bot${BOT}/${j.result.file_path}` : null));

const downloadBytes = (url) => fetch(url).then((r) => r.arrayBuffer());

const getChatMember = (chatId, userId) =>
  fetch(`https://api.telegram.org/bot${BOT}/getChatMember?chat_id=${encodeURIComponent(chatId)}&user_id=${userId}`)
    .then((r) => r.json());

// ---- per-user session state in Supabase table 'bot_users' ----
const getUser = (id) => sbSelect('bot_users', `chat_id=eq.${id}&limit=1`).then((r) => r?.[0]);

const patchUser = (id, patch) => sbUpdate('bot_users', `chat_id=eq.${id}`, patch);

const GENRES = ['پاپ', 'راپ', 'سنتی', 'هیپ‌هاپ', 'الکترونیک', 'راک', 'کلاسیک', 'فولک', 'ترنس', 'جاز', 'بلوز', 'متال'];

const makeMenu = (text, keyboard) =>
  tg('sendMessage', { text, reply_markup: { inline_keyboard: keyboard }, parse_mode: 'HTML' });

export default {
  async fetch(request, env) {
    if (request.method !== 'POST') return new Response('harmony bot');
    BOT = env.TELEGRAM_BOT_TOKEN;
    SUPABASE_URL = env.SUPABASE_URL;
    SUPABASE_KEY = env.SUPABASE_SERVICE_ROLE_KEY;
    ADMIN_ID = Number(env.ADMIN_TELEGRAM_ID);
    CHANNEL_ID = env.CHANNEL_ID || '@Thetextstory';
    let u;
    try { u = await request.json(); } catch { return new Response('bad'); }
    const msg = u.message;
    const cb = u.callback_query;
    if (msg) await handleMessage(msg);
    else if (cb) await handleCallback(cb);
    return new Response('ok');
  },
};

async function handleMessage(msg) {
  const chatId = msg.chat.id;
  const fromId = msg.from.id;
  const text = msg.text || '';
  const isAdmin = fromId === ADMIN_ID;

  // ---- Admin reply mode ----
  const me = await getUser(ADMIN_ID);
  if (isAdmin && me?.mode?.startsWith('reply:')) {
    const target = me.mode.split(':')[1];
    await tg('copyMessage', { chat_id: target, from_chat_id: ADMIN_ID, message_id: msg.message_id });
    await tg('sendMessage', { chat_id: ADMIN_ID, text: `✅ پیام برای ${target} ارسال شد. /cancel برای پایان` });
    return;
  }

  // ---- Commands ----
  if (text.startsWith('/')) {
    const cmd = text.split(' ')[0];
    if (cmd === '/start') return await cmdStart(chatId, fromId);
    if (cmd === '/cancel') { await patchUser(ADMIN_ID, { mode: null }); return tg('sendMessage', { chat_id: ADMIN_ID, text: 'حالت پاسخ بسته شد.' }); }
    if (cmd === '/pending') return await listPending();
    if (cmd === '/contact' && !isAdmin) return await startContact(chatId);
    if (cmd === '/anon' && !isAdmin) return await toggleAnon(chatId);
    if (isAdmin) return;
  }

  // ---- User -> Admin message ----
  if (me?.mode === 'contact' && !isAdmin) {
    await tg('forwardMessage', { chat_id: ADMIN_ID, from_chat_id: chatId, message_id: msg.message_id });
    await tg('sendMessage', {
      chat_id: ADMIN_ID, text: `💬 پیام از ${chatId}`,
      reply_markup: { inline_keyboard: [[{ text: 'پاسخ 💬', callback_data: `reply:${chatId}` }]] },
    });
    await patchUser(chatId, { mode: null });
    return tg('sendMessage', { chat_id: chatId, text: '✅ پیام رسید. ادمین جواب میده.' });
  }

  // ---- Normal flow ----
  const user = await getUser(chatId);
  const step = user?.step || 0;

  if (msg.audio || msg.voice || msg.document) {
    const f = msg.audio || msg.voice || msg.document;
    const id = f.file_id;
    const title = msg.audio?.title || msg.audio?.performer || f.file_name?.replace(/\.[^.]+$/, '') || 'آهنگ';
    const performer = msg.audio?.performer || '';
    const newId = `ps_${Date.now()}_${chatId}`;
    await sbInsert('pending_songs', {
      id: newId, chat_id: chatId, audio_file_id: id, step: 1,
      audio_title: title, audio_performer: performer,
      anonymous: user?.anon ? true : false,
    });
    await patchUser(chatId, { step: 1, data: { id: newId } });
    return makeMenu('📷 کاور آهنگ رو بفرست یا از خود آهنگ بگیر:', [
      [{ text: '🎵 از خود آهنگ', callback_data: `cover:auto:${newId}` }],
      [{ text: '📷 فرستادن عکس', callback_data: `cover:skip:${newId}` }],
      [{ text: '❌ رد', callback_data: `reject:${newId}` }],
    ]);
  }

  if (step === 2 && msg.photo) {
    const id = user.data.id;
    await patchUser(chatId, { step: 3 });
    return makeMenu('📝 متن آهنگ (شعر/توضیح) بفرست یا /skip:', [
      [{ text: '⏭️ رد کردن متن', callback_data: `lyrics:skip:${id}` }],
    ]);
  }

  if (step === 3) {
    const id = user.data.id;
    const lyrics = text === '/skip' ? '' : text;
    await sbUpdate('pending_songs', `id=eq.${id}`, { lyrics });
    await patchUser(chatId, { step: 4 });
    return tg('sendMessage', { chat_id: chatId, text: '✏️ اسم آهنگ رو بنویس:' });
  }

  if (step === 4) {
    const id = user.data.id;
    await sbUpdate('pending_songs', `id=eq.${id}`, { title: text });
    await patchUser(chatId, { step: 5 });
    return tg('sendMessage', { chat_id: chatId, text: '🎤 اسم خواننده رو بنویس:' });
  }

  if (step === 5) {
    const id = user.data.id;
    await sbUpdate('pending_songs', `id=eq.${id}`, { artist: text });
    await patchUser(chatId, { step: 6 });
    const kb = GENRES.map((g) => [{ text: g, callback_data: `genre:${g}:${id}` }]);
    kb.push([{ text: '❌ رد', callback_data: `reject:${id}` }]);
    return makeMenu('🎭 آهنگ توی کدوم دسته‌بندیه؟', kb);
  }

  if (isAdmin) {
    return tg('sendMessage', { chat_id: ADMIN_ID, text: 'دستور ناشناخته. /pending لیست آهنگ‌ها.' });
  }
  return tg('sendMessage', { chat_id: chatId, text: 'سلام! فایل صوتی بفرست 🎵' });
}

async function cmdStart(chatId, fromId) {
  const member = await getChatMember(CHANNEL_ID, fromId);
  const status = member?.result?.status;
  if (!['member', 'administrator', 'creator'].includes(status)) {
    return makeMenu(
      'سلام! برای استفاده از ربات، ابتدا در کانال زیر عضو شوید 👇\nبعد دوباره /start بزن.',
      [[{ text: '📢 عضویت در کانال', url: `https://t.me/${CHANNEL_ID.replace('@', '')}` }]]
    );
  }
  return tg('sendMessage', {
    chat_id: chatId,
    text: 'سلام! به ربات Iranian Sedà خوش آمدی 🎵\nفایل صوتی بفرست.\n\n/contact پیام به ادمین\n/anon حالت ناشناس',
  });
}

async function startContact(chatId) {
  await patchUser(chatId, { mode: 'contact' });
  return tg('sendMessage', { chat_id: chatId, text: '💬 پیامت رو بنویس:' });
}

async function toggleAnon(chatId) {
  const u = await getUser(chatId);
  const newVal = !(u?.anon ?? false);
  await patchUser(chatId, { anon: newVal });
  return tg('sendMessage', {
    chat_id: chatId,
    text: newVal
      ? '🕶️ حالت ناشناس روشن شد (تا استارت بعدی می‌مونه).'
      : 'حالت ناشناس خاموش شد.',
  });
}

async function listPending() {
  const rows = await sbSelect('pending_songs', 'status=eq.pending&order=created_at.desc');
  if (!rows.length) return tg('sendMessage', { chat_id: ADMIN_ID, text: 'هیچ آهنگی در صف نیست.' });
  for (const r of rows.slice(0, 10)) await sendAdminSong(r);
}

async function sendAdminSong(r) {
  const cap = `🎵 <b>${r.title || 'بدون نام'}</b>\n🎤 ${r.artist || 'نامشخص'}\n🎭 ${r.genre || '-'}\n${r.anonymous ? '🕶️ ناشناس' : `👤 ${r.chat_id}`}`;
  if (r.cover_file_id) {
    await tg('sendPhoto', { chat_id: ADMIN_ID, photo: r.cover_file_id, caption: cap, parse_mode: 'HTML', reply_markup: adminKeyboard(r.id) });
  } else {
    await tg('sendMessage', { chat_id: ADMIN_ID, text: cap, parse_mode: 'HTML', reply_markup: adminKeyboard(r.id) });
  }
  if (r.audio_file_id) {
    await tg('sendAudio', { chat_id: ADMIN_ID, audio: r.audio_file_id, caption: '🎧 فایل صوتی' });
  }
}

function adminKeyboard(id) {
  return {
    inline_keyboard: [
      [
        { text: '✅ تأیید', callback_data: `approve:${id}` },
        { text: '❌ رد', callback_data: `reject:${id}` },
      ],
      [
        { text: '🗑️ حذف', callback_data: `delete:${id}` },
        { text: '💬 پاسخ', callback_data: `reply:${id}` },
      ],
    ],
  };
}

async function handleCallback(cb) {
  const data = cb.data;
  const fromId = cb.from.id;
  const chatId = cb.message.chat.id;
  const mid = cb.message.message_id;
  await tg('answerCallbackQuery', { callback_query_id: cb.id });

  if (data.startsWith('cover:')) {
    const [, action, id] = data.split(':');
    await sbUpdate('pending_songs', `id=eq.${id}`, { step: 2, cover_from_audio: action === 'auto' });
    await patchUser(chatId, { step: 2 });
    if (action === 'auto') {
      return tg('editMessageText', { chat_id: chatId, message_id: mid, text: '📝 متن آهنگ بفرست یا /skip:', reply_markup: { inline_keyboard: [[{ text: '⏭️ رد کردن', callback_data: `lyrics:skip:${id}` }]] } });
    }
    return tg('editMessageText', { chat_id: chatId, message_id: mid, text: '📷 عکس کاور رو بفرست:' });
  }

  if (data.startsWith('lyrics:skip')) {
    const id = data.split(':')[1];
    await sbUpdate('pending_songs', `id=eq.${id}`, { lyrics: '' });
    await patchUser(chatId, { step: 4 });
    return tg('sendMessage', { chat_id: chatId, text: '✏️ اسم آهنگ رو بنویس:' });
  }

  if (data.startsWith('genre:')) {
    const [, g, id] = data.split(':');
    await sbUpdate('pending_songs', `id=eq.${id}`, { genre: g, step: 7 });
    await patchUser(chatId, { step: 7 });
    return tg('sendMessage', { chat_id: chatId, text: `✅ در دسته‌بندی «${g}» ثبت شد! منتظر تأیید 😊` });
  }

  if (fromId === ADMIN_ID && data.startsWith('approve:')) {
    const id = data.split(':')[1];
    const r = (await sbSelect('pending_songs', `id=eq.${id}&limit=1`))?.[0];
    if (!r) return;
    await publishToChannel(r, id);
    await sbUpdate('pending_songs', `id=eq.${id}`, { status: 'approved', step: 99 });
    await tg('editMessageReplyMarkup', { chat_id: ADMIN_ID, message_id: mid, reply_markup: { inline_keyboard: [] } });
    await tg('sendMessage', { chat_id: ADMIN_ID, text: `✅ تایید شد: ${r.title || id}` });
    if (r.chat_id) await tg('sendMessage', { chat_id: r.chat_id, text: `🎉 آهنگ شما «${r.title}» تأیید و منتشر شد!` });
    return;
  }

  if (fromId === ADMIN_ID && data.startsWith('reject:')) {
    const id = data.split(':')[1];
    const r = (await sbSelect('pending_songs', `id=eq.${id}&limit=1`))?.[0];
    if (!r) return;
    await sbUpdate('pending_songs', `id=eq.${id}`, { status: 'rejected', step: 99 });
    await tg('editMessageReplyMarkup', { chat_id: ADMIN_ID, message_id: mid, reply_markup: { inline_keyboard: [] } });
    await tg('sendMessage', { chat_id: ADMIN_ID, text: `❌ رد شد: ${r.title || id}` });
    if (r.chat_id) await tg('sendMessage', { chat_id: r.chat_id, text: 'متأسفانه آهنگ شما رد شد.' });
    return;
  }

  if (fromId === ADMIN_ID && data.startsWith('delete:')) {
    const id = data.split(':')[1];
    await sbDelete('pending_songs', `id=eq.${id}`);
    await tg('editMessageReplyMarkup', { chat_id: ADMIN_ID, message_id: mid, reply_markup: { inline_keyboard: [] } });
    await tg('sendMessage', { chat_id: ADMIN_ID, text: `🗑️ حذف شد: ${id}` });
    return;
  }

  if (fromId === ADMIN_ID && data.startsWith('reply:')) {
    const target = data.split(':')[1];
    let chat = target;
    const row = await sbSelect('pending_songs', `id=eq.${target}&limit=1`);
    if (row?.length) chat = row[0].chat_id;
    await patchUser(ADMIN_ID, { mode: `reply:${chat}` });
    return tg('sendMessage', { chat_id: ADMIN_ID, text: `✍️ پاسخ به ${chat}. بنویس (/cancel برای پایان):` });
  }
}

async function publishToChannel(r, id) {
  try {
    const audioBytes = await downloadBytes(await getFileUrl(r.audio_file_id));
    await sbUpload('songs', `${id}.mp3`, audioBytes, 'audio/mpeg');
    let coverUrl = '';
    if (r.cover_file_id) {
      const covBytes = await downloadBytes(await getFileUrl(r.cover_file_id));
      await sbUpload('covers', `${id}.jpg`, covBytes, 'image/jpeg');
      coverUrl = `${SUPABASE_URL}/storage/v1/object/public/covers/${id}.jpg`;
    }
    const songUrl = `${SUPABASE_URL}/storage/v1/object/public/songs/${id}.mp3`;
    await sbInsert('songs', {
      id, title: r.title, artist: r.artist, genre: r.genre || 'عمومی',
      audio_url: songUrl, cover_url: coverUrl, plays: 0,
    });
    const text = `🎶 یکی از رفقا آهنگ جدید توی برنامه گذاشته با هم بشنویم:\n\n🎵 <b>${r.title}</b>\n🎤 ${r.artist || 'نامشخص'}\n🎭 ${r.genre || 'عمومی'}\n\n📱 Iranian Sedà`;
    if (coverUrl) {
      await tg('sendPhoto', { chat_id: CHANNEL_ID, photo: coverUrl, caption: text, parse_mode: 'HTML' });
    }
    await tg('sendAudio', { chat_id: CHANNEL_ID, audio: songUrl, caption: text, parse_mode: 'HTML', title: r.title, performer: r.artist });
  } catch (e) {
    await tg('sendMessage', { chat_id: ADMIN_ID, text: `⚠️ خطا در انتشار: ${e.message || e}` });
  }
}
