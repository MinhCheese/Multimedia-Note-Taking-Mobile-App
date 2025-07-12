using System;
using System.Collections.Generic;
using System.ComponentModel.DataAnnotations.Schema;
using System.ComponentModel.DataAnnotations;

namespace LoginApi.Models
{
    public class Tag
    {
        [Key]
        [Column("id")]
        public Guid Id { get; set; }
        [Column("name")]
        public string Name { get; set; } = string.Empty;

        public ICollection<NoteTag> NoteTags { get; set; } = new List<NoteTag>();
    }
}
