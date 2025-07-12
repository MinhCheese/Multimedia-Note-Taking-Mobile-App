using LoginApi.Data;
using LoginApi.Models;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using Microsoft.AspNetCore.Http;
using System.IO;
using Microsoft.AspNetCore.Hosting;

namespace LoginApi.Controllers
{
    [ApiController]
    [Route("api/[controller]")]
    public class NotesController : ControllerBase
    {
        private readonly AppDbContext _context;
        private readonly IWebHostEnvironment _env;

        public NotesController(AppDbContext context, IWebHostEnvironment env)
        {
            _context = context;
            _env = env;
        }

        [HttpGet("user/{userId}")]
        public async Task<IActionResult> GetNotesByUser(Guid userId)
        {
            var notes = await _context.Notes
                .Where(n => n.UserId == userId && !n.IsDeleted)
                .Include(n => n.MediaFiles.Where(m => !m.IsDeleted))
                .Include(n => n.NoteTags)
                    .ThenInclude(nt => nt.Tag)
                .Select(n => new
                {
                    n.Id,
                    n.Title,
                    n.Content,
                    n.CreatedAt,
                    Tags = n.NoteTags.Select(nt => nt.Tag.Name).ToList(),
                    MediaFiles = n.MediaFiles.Select(m => new
                    {
                        m.FileType,
                        m.FilePath,
                        m.IsDeleted
                    }).ToList()
                })
                .ToListAsync();

            return Ok(notes);
        }


        [HttpPost]
        public async Task<IActionResult> CreateNote([FromBody] CreateNoteRequestDto request)
        {
            var user = await _context.Users.FindAsync(request.UserId);
            if (user == null)
            {
                return NotFound("User not found.");
            }

            var note = new Note
            {
                Id = Guid.NewGuid(),
                UserId = request.UserId,
                Title = request.Title,
                Content = request.Content,
                CreatedAt = DateTime.UtcNow,
                IsDeleted = false
            };

            _context.Notes.Add(note);

            // Gắn tags (nếu có)
            foreach (var tagName in request.Tags)
            {
                var tag = await _context.Tags.FirstOrDefaultAsync(t => t.Name == tagName);
                if (tag == null)
                {
                    tag = new Tag
                    {
                        Id = Guid.NewGuid(),
                        Name = tagName
                    };
                    _context.Tags.Add(tag);
                }

                var noteTag = new NoteTag
                {
                    NoteId = note.Id,
                    TagId = tag.Id
                };
                _context.NoteTags.Add(noteTag);
            }

            await _context.SaveChangesAsync();
            return Ok(new { message = "Note created successfully", noteId = note.Id });
        }

        [HttpPut("{id}")]
        public async Task<IActionResult> UpdateNote(Guid id, [FromBody] UpdateNoteRequestDto request)
        {
            var note = await _context.Notes.FirstOrDefaultAsync(n => n.Id == id && n.IsDeleted == false);
            if (note == null)
            {
                return NotFound("Note not found.");
            }

            note.Title = request.Title;
            note.Content = request.Content;

            // Xóa hết tag cũ
            var existingTags = _context.NoteTags.Where(nt => nt.NoteId == id);
            _context.NoteTags.RemoveRange(existingTags);

            // Gắn tags mới
            foreach (var tagName in request.Tags)
            {
                var tag = await _context.Tags.FirstOrDefaultAsync(t => t.Name == tagName);
                if (tag == null)
                {
                    tag = new Tag
                    {
                        Id = Guid.NewGuid(),
                        Name = tagName
                    };
                    _context.Tags.Add(tag);
                }

                _context.NoteTags.Add(new NoteTag
                {
                    NoteId = id,
                    TagId = tag.Id
                });
            }

            await _context.SaveChangesAsync();
            return Ok(new { message = "Note updated successfully" });
        }

        [HttpDelete("{id}")]
        public async Task<IActionResult> DeleteNote(Guid id)
        {
            var note = await _context.Notes
                .Include(n => n.MediaFiles)
                .FirstOrDefaultAsync(n => n.Id == id);

            if (note == null)
                return NotFound();

            note.IsDeleted = true;

            // Soft delete media files liên kết
            foreach (var media in note.MediaFiles)
            {
                media.IsDeleted = true;
            }

            await _context.SaveChangesAsync();
            return NoContent();
        }




        [HttpPost("upload-audio")]
        public async Task<IActionResult> UploadAudio([FromForm] IFormFile file, [FromForm] Guid noteId)
        {
            if (file == null || file.Length == 0)
                return BadRequest(new { message = "File rỗng" });

            var folderPath = Path.Combine(Directory.GetCurrentDirectory(), "wwwroot", "uploads", "audio");
            if (!Directory.Exists(folderPath)) Directory.CreateDirectory(folderPath);

            var fileName = $"{Guid.NewGuid()}.aac";
            var fullPath = Path.Combine(folderPath, fileName);

            using (var stream = new FileStream(fullPath, FileMode.Create))
            {
                await file.CopyToAsync(stream);
            }

            var relativePath = $"/uploads/audio/{fileName}";

            var media = new MediaFile
            {
                Id = Guid.NewGuid(),
                NoteId = noteId,
                FileType = "audio",
                FilePath = relativePath,
                UploadedAt = DateTime.UtcNow,
                IsDeleted = false
            };

            _context.MediaFiles.Add(media);
            await _context.SaveChangesAsync();

            return Ok(new
            {
                message = "Tải file ghi âm thành công!",
                filePath = relativePath // ✅ Trả về cho phía Flutter
            });
        }


        [HttpGet("latest/{userId}")]
        public async Task<IActionResult> GetLatestNoteId(Guid userId)
        {
            var latestNote = await _context.Notes
                .Where(n => n.UserId == userId && !n.IsDeleted)
                .OrderByDescending(n => n.CreatedAt)
                .FirstOrDefaultAsync();

            if (latestNote == null)
            {
                return NotFound("Không tìm thấy ghi chú.");
            }

            return Ok(new { noteId = latestNote.Id });
        }

        [HttpPost("upload-image")]
        public async Task<IActionResult> UploadImage([FromForm] IFormFile file, [FromForm] Guid noteId)
        {
            if (file == null || file.Length == 0)
                return BadRequest(new { message = "File ảnh rỗng" });

            var folderPath = Path.Combine(Directory.GetCurrentDirectory(), "wwwroot", "uploads", "images");
            if (!Directory.Exists(folderPath)) Directory.CreateDirectory(folderPath);

            var fileExt = Path.GetExtension(file.FileName);
            var fileName = $"{Guid.NewGuid()}{fileExt}";
            var fullPath = Path.Combine(folderPath, fileName);

            using (var stream = new FileStream(fullPath, FileMode.Create))
            {
                await file.CopyToAsync(stream);
            }

            var relativePath = $"/uploads/images/{fileName}";

            var media = new MediaFile
            {
                Id = Guid.NewGuid(),
                NoteId = noteId,
                FileType = "image",
                FilePath = relativePath,
                UploadedAt = DateTime.UtcNow,
                IsDeleted = false
            };

            _context.MediaFiles.Add(media);
            await _context.SaveChangesAsync();

            return Ok(new
            {
                message = "Tải ảnh lên thành công!",
                filePath = relativePath // ✅ Flutter sẽ lấy để hiển thị ảnh
            });
        }

        [HttpPost("delete-media")]
        public async Task<IActionResult> DeleteMediaFile([FromBody] DeleteMediaFileRequestDto request)
        {
            if (string.IsNullOrEmpty(request.FilePath))
                return BadRequest(new { message = "Thiếu đường dẫn file" });

            // Tìm media file trong database
            var media = await _context.MediaFiles.FirstOrDefaultAsync(m => m.FilePath == request.FilePath && !m.IsDeleted);
            if (media == null)
                return NotFound(new { message = "Không tìm thấy file" });

            // ❗ Chỉ đánh dấu là đã xoá (soft delete)
            media.IsDeleted = true;

            await _context.SaveChangesAsync();
            return Ok(new { message = "Đã xoá media thành công" });
        }




    }

}
