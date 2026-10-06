(function () {
  var STORAGE_KEY = "formycareer_cookie_consent_v1";
  var banner = document.getElementById("cookie-consent");
  if (!banner) return;

  function setConsent(value) {
    try {
      localStorage.setItem(STORAGE_KEY, value);
    } catch (e) {
      return;
    }
  }

  function getConsent() {
    try {
      return localStorage.getItem(STORAGE_KEY);
    } catch (e) {
      return null;
    }
  }

  function hideBanner() {
    banner.setAttribute("hidden", "");
  }

  var current = getConsent();
  if (!current) {
    banner.removeAttribute("hidden");
  }

  var acceptBtn = banner.querySelector("[data-consent-accept]");
  var declineBtn = banner.querySelector("[data-consent-decline]");

  if (acceptBtn) {
    acceptBtn.addEventListener("click", function () {
      setConsent("accepted");
      hideBanner();
    });
  }

  if (declineBtn) {
    declineBtn.addEventListener("click", function () {
      setConsent("declined");
      hideBanner();
    });
  }
})();
