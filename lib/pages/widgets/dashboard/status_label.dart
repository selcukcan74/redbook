String statusLabel(String status) {
  switch (status) {
    case "accepted":
      return "Onaylandı";
    case "sent":
      return "Gönderildi";
    case "rejected":
      return "Reddedildi";
    case "expired":
      return "Süresi Doldu";
    case "draft":
      return "Taslak";
    default:
      return status;
  }
}
