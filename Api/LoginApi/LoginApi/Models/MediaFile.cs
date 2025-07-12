using System;
using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;

namespace LoginApi.Models
{
    public class MediaFile
    {
        [Key]
        [Column("id")]
        public Guid Id { get; set; }

        [Required]
        [Column("note_id")]
        public Guid NoteId { get; set; }

        [Required]
        [Column("file_type")]
        public string FileType { get; set; } = string.Empty;

        [Required]
        [Column("file_path")]
        public string FilePath { get; set; } = string.Empty;

        [Column("is_deleted")]
        public bool IsDeleted { get; set; } = false;

        [Column("uploaded_at")] // ✅ đúng tên cột trong DB
        public DateTime UploadedAt { get; set; } = DateTime.UtcNow;

        [ForeignKey("NoteId")]
        public Note? Note { get; set; }
    }
}
