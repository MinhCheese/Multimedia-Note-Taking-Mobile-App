using System.ComponentModel.DataAnnotations.Schema;

namespace LoginApi.Models
{
    [Table("users")]
    public class User
    {
        [Column("id")]
        public Guid Id { get; set; }

        [Column("name")]
        public string? Name { get; set; }

        [Column("email")]
        public string Email { get; set; }

        [Column("password_hash")]
        public string PasswordHash { get; set; }

        [Column("created_at")]
        public DateTime CreatedAt { get; set; }
    }
}
