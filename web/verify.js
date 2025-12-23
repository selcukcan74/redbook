const SUPABASE_URL = "https://XXXX.supabase.co";
const SUPABASE_ANON_KEY = "PUBLIC_ANON_KEY";

const params = new URLSearchParams(window.location.search);
const token = params.get("token");

const loading = document.getElementById("loading");
const content = document.getElementById("content");

if (!token) {
  loading.innerText = "Geçersiz bağlantı.";
  throw new Error("Token yok");
}

fetch(`${SUPABASE_URL}/rest/v1/quotes?verify_token=eq.${token}`, {
  headers: {
    apikey: SUPABASE_ANON_KEY,
    Authorization: `Bearer ${SUPABASE_ANON_KEY}`,
  },
})
.then(res => res.json())
.then(data => {
  if (!data || data.length === 0) {
    loading.innerText = "Teklif bulunamadı.";
    return;
  }

  const quote = data[0];
  document.getElementById("quoteNo").innerText = quote.quote_number;

  const statusEl = document.getElementById("statusText");
  if (quote.status === "accepted") {
    statusEl.innerText = "✔ Bu teklif ONAYLANMIŞTIR";
    statusEl.className = "status ok";
  } else if (quote.status === "rejected") {
    statusEl.innerText = "✘ Bu teklif REDDEDİLMİŞTİR";
    statusEl.className = "status reject";
  } else {
    statusEl.innerText = "Bu teklif henüz sonuçlandırılmamıştır";
    statusEl.className = "status pending";
  }

  document.getElementById("dateText").innerText =
    "Oluşturulma Tarihi: " +
    new Date(quote.created_at).toLocaleDateString("tr-TR");

  loading.style.display = "none";
  content.style.display = "block";
})
.catch(err => {
  loading.innerText = "Bir hata oluştu.";
  console.error(err);
});
