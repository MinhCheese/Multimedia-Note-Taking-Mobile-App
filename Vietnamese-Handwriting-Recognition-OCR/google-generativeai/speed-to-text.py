from fastapi import FastAPI
from pydantic import BaseModel
import google.generativeai as genai
import json
from datetime import datetime

# Khởi tạo Gemini AI (Lấy key miễn phí tại Google AI Studio)
genai.configure(api_key="AIzaSyBI9ulRZyWjiqtPNPhT1Dex5YlRwIb-qqU")

# Dùng bản Flash 2.5 cho tốc độ cực nhanh
model = genai.GenerativeModel('gemini-2.5-flash') 

class VoiceRequest(BaseModel):
    text: str

@app.post("/parse-voice-note")
async def parse_voice_note(req: VoiceRequest):
    # Lấy thời gian hiện tại để AI biết làm mốc suy luận (VD: "sáng mai", "chiều nay")
    current_time = datetime.now().strftime("%Y-%m-%dT%H:%M:%S")
    
    # PROMPT ENGINEERING: Ép AI trả về đúng khuôn NoteModel của Flutter
    prompt = f"""
    Bạn là một trợ lý AI phân tích ngôn ngữ tự nhiên.
    Thời gian hiện tại của hệ thống là: {current_time}
    
    Nhiệm vụ của bạn là đọc câu nói của người dùng và trích xuất thông tin để tạo Ghi chú.
    Câu nói: "{req.text}"
    
    Hãy trả về KẾT QUẢ DUY NHẤT LÀ MỘT OBJECT JSON, không kèm bất kỳ lời giải thích nào. 
    JSON phải có ĐÚNG 4 trường sau để khớp với Database:
    {{
        "title": "Tiêu đề ngắn gọn (khoảng 3-7 chữ)",
        "content": "Toàn bộ nội dung câu nói, có thể viết hoa chữ cái đầu và sửa lỗi chính tả cho chuẩn xác",
        "tags": ["Tên nhãn"], // Trả về mảng chứa đúng 1 nhãn. Chọn 1 trong 4 nhãn sau: 'Học tập', 'Công việc', 'Cá nhân', 'Khác'
        "reminderAt": "YYYY-MM-DDTHH:MM:00" // Thời gian nhắc nhở (nếu có nhắc đến thời gian). Nếu câu nói không có thời gian, trả về null.
    }}
    """
    
    try:
        response = model.generate_content(prompt)
        
        # Dọn dẹp chuỗi trả về để loại bỏ các ký tự Markdown (```json) nếu AI lỡ thêm vào
        raw_text = response.text.strip()
        if raw_text.startswith("```json"):
            raw_text = raw_text[7:]
        if raw_text.endswith("```"):
            raw_text = raw_text[:-3]
            
        parsed_data = json.loads(raw_text.strip())
        
        # Trả về kết quả hoàn hảo cho Flutter
        return {
            "status": "success",
            "parsed_data": parsed_data
        }
    except Exception as e:
        return {"status": "error", "message": str(e)}