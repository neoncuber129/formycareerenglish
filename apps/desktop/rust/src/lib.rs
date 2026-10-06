#[no_mangle]
pub extern "C" fn formycareer_ocr_version() -> u32 {
    1
}

pub fn extract_text_mock() -> String {
    "Hello from Rust OCR (placeholder)".to_string()
}
