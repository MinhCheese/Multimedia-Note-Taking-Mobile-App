using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using LoginApi.Data;

namespace LoginApi.Controllers
{
    [ApiController]
    [Route("api/Media")]

    public class MediaController : ControllerBase
    {
        private readonly AppDbContext _context;

        public MediaController(AppDbContext context)
        {
            _context = context;
        }

        // GET: api/media/user/{userId}
        [HttpGet("user/{userId}")]
        public async Task<IActionResult> GetUserMediaFiles(Guid userId)
        {
            var files = await _context.MediaFiles
                .Include(m => m.Note) 
                .Where(m => !m.IsDeleted && m.Note.UserId == userId)
                .Select(m => new
                {
                    m.Id,
                    m.FileType,
                    m.FilePath,
                    m.NoteId,
                    m.UploadedAt,
                    m.DisplayName
                })
                .ToListAsync();

            return Ok(files);
        }

        public class RenameMediaRequest
        {
            public string NewDisplayName { get; set; } = string.Empty;
        }

        [HttpPut("{id}/rename")]
        public async Task<IActionResult> RenameMedia(Guid id, [FromBody] RenameMediaRequest request)
        {
            var media = await _context.MediaFiles.FindAsync(id);
            if (media == null)
            {
                return NotFound();
            }

            media.DisplayName = request.NewDisplayName;
            await _context.SaveChangesAsync();

            return NoContent();
        }



    }
}
