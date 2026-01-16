const fs = require('fs');
try {
  fs.copyFileSync('C:/Users/advhm/.gemini/antigravity/brain/4b4c375e-b1eb-4a70-9018-c47b0a589e2d/uploaded_image_1766856590995.jpg', 'assets/logo.jpg');
  console.log('SUCCESS');
} catch (e) {
  console.error(e);
}
