// Supabase Edge Function: Telegram bot webhook for Iranian Spotify.
// Receives updates from Telegram, walks the user through 3 steps
// (audio -> cover -> lyrics), then asks the admin to approve.
// On approval, uploads to storage + inserts into `songs`.

// @ts-nocheck  (Supabase edge runtime provides Deno types)

import { createClient } from "https://esm.sh/@supabase/supabase-js@2";

const BOT_TOKEN = Deno.env.get("TELEGRAM_BOT_TOKEN")!;
const ADMIN_ID = Number(Deno.env.get("ADMIN_TELEGRAM_ID")!);
const SUPABASE_URL = Deno.env.get("SUPABASE_URL")!;
const SUPABASE_SERVICE_ROLE = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!;

const ADMIN_CONV = "admin_main";

async function tg(method: string, body: Record<string, unknown>) {
  const r = await fetch(`https://api.telegram.org/bot${BOT_TOKEN}/${method}`, {
    method: "POST",
    headers: { "Content-Type": "application/json" },
    body: JSON.stringify(body),
  });
  return r.json();
}

function getFileUrl(fileId: string): string {
  return `https://api.telegram.org/file/bot${BOT_TOKEN}/${fileId}`;
}

async function downloadToBytes(url: string): Promise<Uint8Array> {
  const r = await fetch(url);
  return new Uint8Array(await r.arrayBuffer());
}

export const handler = async (req: Request) => {
  if (req.method !== "POST") return new Response("ok");
  const update = await req.json();
  const msg = update.message;
  if (!msg) return new Response("ok");

  const chatId = msg.chat.id;
  const fromId = msg.from.id;
  const text = msg.text;

  const sb = createClient(SUPABASE_URL, SUPABASE_SERVICE_ROLE);

  // Admin conversation: approve / reject pending submissions
  if (fromId === ADMIN_ID && text && text.startsWith("/")) {
    return handleAdminCommand(sb, tg, chatId, text);
  }

  // Normal user flow
  // Step 1: user sends an audio
  if (msg.audio || msg.voice || msg.document) {
    const fileId = (msg.audio?.file_id ?? msg.voice?.file_id ?? msg.document?.file_id);
    // start a fresh pending row
    const { data, error } = await sb
      .from("pending_songs")
      .insert({ chat_id: chatId, step: 2, audio_file_id: fileId, status: "collecting" })
      .select()
      .single();
    if (error) {
      await tg("sendMessage", { chat_id: chatId, text: "خطا در ثبت آهنگ. لطفاً دوباره تلاش کن." });
      return new Response("ok");
    }
    await tg("sendMessage", {
      chat_id: chatId,
      text: "✅ آهنگ دریافت شد.\nحالا **عکس کاور** آهنگ رو بفرست (اختیاری — اگه نداری بنویس «رد»).",
    });
    return new Response("ok");
  }

  // Step 2: user sends a cover (photo) or skips
  if (msg.photo || (text && text.trim() === "رد")) {
    const { data: rows } = await sb
      .from("pending_songs")
      .select()
      .eq("chat_id", chatId)
      .eq("status", "collecting")
      .order("created_at", { ascending: false })
      .limit(1);
    const row = rows?.[0];
    if (!row) {
      await tg("sendMessage", { chat_id: chatId, text: "اول آهنگ رو بفرست 🎵" });
      return new Response("ok");
    }
    const coverFileId = msg.photo ? msg.photo[msg.photo.length - 1].file_id : null;
    await sb.from("pending_songs").update({ cover_file_id: coverFileId, step: 3 }).eq("id", row.id);
    await tg("sendMessage", {
      chat_id: chatId,
      text: "✅ کاور ثبت شد.\nحالا **متن آهنگ** رو بنویس (اختیاری — اگه نداری بنویس «رد»).",
    });
    return new Response("ok");
  }

  // Step 3: user sends lyrics (text) or skips -> ready, notify admin
  if (text && text.trim() !== "رد") {
    const { data: rows } = await sb
      .from("pending_songs")
      .select()
      .eq("chat_id", chatId)
      .eq("status", "collecting")
      .order("created_at", { ascending: false })
      .limit(1);
    const row = rows?.[0];
    if (!row) {
      await tg("sendMessage", { chat_id: chatId, text: "دستور نامفهوم. آهنگ رو بفرست تا شروع کنیم 🎵" });
      return new Response("ok");
    }
    await sb.from("pending_songs").update({ lyrics: text, status: "pending" }).eq("id", row.id);
    // notify admin
    await tg("sendMessage", {
      chat_id: ADMIN_ID,
      text: `🆕 آهنگ جدید در انتظار تأیید از کاربر ${chatId}\nبرای تأیید: /approve ${row.id}\nبرای رد: /reject ${row.id}`,
    });
    await tg("sendMessage", { chat_id: chatId, text: "✅ درخواست ثبت شد و در انتظار تأیید ادمینه. ممنون! 🙏" });
    return new Response("ok");
  }

  // fallback
  await tg("sendMessage", {
    chat_id: chatId,
    text: "سلام! برای افزودن آهنگ، اول فایل صوتی رو بفرست 🎵",
  });
  return new Response("ok");
};

async function handleAdminCommand(
  sb: any,
  tgFn: any,
  chatId: number,
  text: string,
) {
  const parts = text.split(" ");
  const cmd = parts[0];
  if (cmd === "/pending") {
    const { data } = await sb.from("pending_songs").select().eq("status", "pending");
    if (!data || data.length === 0) {
      await tgFn("sendMessage", { chat_id: chatId, text: "هیچ آهنگ در انتظاری نیست ✅" });
      return new Response("ok");
    }
    for (const r of data) {
      await tgFn("sendMessage", {
        chat_id: chatId,
        text: `🆕 آهنگ ${r.id}\nبرای تأیید: /approve ${r.id}\nبرای رد: /reject ${r.id}`,
      });
    }
    return new Response("ok");
  }
  if (cmd === "/approve" && parts[1]) {
    const id = parts[1];
    const { data: row } = await sb.from("pending_songs").select().eq("id", id).single();
    if (!row) return new Response("ok");
    await publish(sb, tgFn, row, chatId, id);
    return new Response("ok");
  }
  if (cmd === "/reject" && parts[1]) {
    await sb.from("pending_songs").update({ status: "rejected" }).eq("id", parts[1]);
    await tgFn("sendMessage", { chat_id: chatId, text: "❌ رد شد." });
    return new Response("ok");
  }
  await tgFn("sendMessage", { chat_id: chatId, text: "دستورها:\n/pending لیست در انتظار\n/approve <id>\n/reject <id>" });
  return new Response("ok");
}

async function publish(sb: any, tgFn: any, row: any, adminChat: number, id: string) {
  try {
    // download audio + cover, upload to storage
    const audioBytes = await downloadToBytes(getFileUrl(row.audio_file_id));
    const audioPath = `${id}.mp3`;
    await sb.storage.from("songs").upload(audioPath, audioBytes, { contentType: "audio/mpeg", upsert: true });

    let coverUrl = "";
    if (row.cover_file_id) {
      const coverBytes = await downloadToBytes(getFileUrl(row.cover_file_id));
      const coverPath = `${id}.jpg`;
      await sb.storage.from("covers").upload(coverPath, coverBytes, { contentType: "image/jpeg", upsert: true });
      coverUrl = `${SUPABASE_URL}/storage/v1/object/public/covers/${coverPath}`;
    }
    const audioUrl = `${SUPABASE_URL}/storage/v1/object/public/songs/${audioPath}`;

    const title = (row.title || "بدون نام").toString();
    const { error } = await sb.from("songs").insert({
      title,
      artist: row.artist || "ناشناس",
      audio_url: audioUrl,
      cover_url: coverUrl,
      lyrics: row.lyrics || "",
      genre: "",
      album: "",
      plays: 0,
    });
    if (error) throw error;
    await sb.from("pending_songs").update({ status: "approved" }).eq("id", id);
    await tgFn("sendMessage", { chat_id: adminChat, text: `✅ آهنگ «${title}» منتشر شد!` });
  } catch (e) {
    await tgFn("sendMessage", { chat_id: adminChat, text: `خطا در انتشار: ${String(e)}` });
  }
}
