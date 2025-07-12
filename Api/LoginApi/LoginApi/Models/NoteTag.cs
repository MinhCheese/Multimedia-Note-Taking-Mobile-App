using System;
using System.ComponentModel.DataAnnotations.Schema;

namespace LoginApi.Models
{
    public class NoteTag
    {
        [Column("note_id")]
        public Guid NoteId { get; set; }

        [Column("tag_id")]
        public Guid TagId { get; set; }

        public Note? Note { get; set; }
        public Tag? Tag { get; set; }
    }
}
