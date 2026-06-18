const fs = require('fs');

const keys = {
  "login_title": "Shop Admin Login 👋",
  "login_subtitle": "Manage your shop with ease",
  "username_or_email": "Username or Email",
  "username_email_hint": "admin@shop.com",
  "please_enter_username_email": "Please enter your username or email",
  "enter_your_password": "Enter your password",
  "please_enter_password": "Please enter your password",
  "login_btn": "Login",
  "no_account": "Don't have a shop account? ",
  "apply_now": "Apply Now",
  "login_failed": "Login failed",
  "unexpected_error": "An unexpected error occurred",
  "register_title": "Become a Partner 🚀",
  "register_subtitle": "Apply now to open your online shop and reach more customers.",
  "shop_name_hint": "e.g., My Awesome Shop",
  "please_enter_shop_name": "Please enter your shop name",
  "owner_name": "Owner Name",
  "owner_name_hint": "Enter your full name",
  "please_enter_owner_name": "Please enter owner name",
  "phone_hint": "e.g., 09xxxxxxxxx",
  "please_enter_phone": "Please enter your phone number",
  "email_optional": "Email Address (Optional)",
  "submit_application": "Submit Application",
  "registration_success": "Application submitted successfully! Our team will contact you shortly to verify and activate your shop account.",
  "registration_failed": "Registration failed"
};

const files = ['assets/lang/en.json', 'assets/lang/my.json', 'assets/lang/th.json'];

files.forEach(file => {
  const data = JSON.parse(fs.readFileSync(file, 'utf8'));
  for (const [key, value] of Object.entries(keys)) {
    if (!data[key]) {
      data[key] = value;
    }
  }
  fs.writeFileSync(file, JSON.stringify(data, null, 2), 'utf8');
});
console.log('Done updating JSONs.');
