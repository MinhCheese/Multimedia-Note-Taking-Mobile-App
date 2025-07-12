using System;
using System.Collections.Generic;
using System.ComponentModel.DataAnnotations.Schema;

namespace LoginApi.Models
{
    public class Note
    {
        [Column("id")]
        public Guid Id { get; set; }
        [Column("user_id")]
        public Guid UserId { get; set; }
        [Column("title")]
        public string? Title { get; set; }
        [Column("content")]
        public string? Content { get; set; }
        [Column("is_deleted")]
        public bool IsDeleted { get; set; }
        [Column("created_at")]
        public DateTime CreatedAt { get; set; }
        [Column("updated_at")]
        public DateTime? UpdatedAt { get; set; }

        public User? User { get; set; }

        
        public ICollection<NoteTag> NoteTags { get; set; } = new List<NoteTag>();
        public ICollection<MediaFile> MediaFiles { get; set; } = new List<MediaFile>();

    }
}
