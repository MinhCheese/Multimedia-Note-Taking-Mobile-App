using LoginApi.Models;
using Microsoft.EntityFrameworkCore;

namespace LoginApi.Data
{
    public class AppDbContext : DbContext
    {
        public AppDbContext(DbContextOptions options) : base(options) { }

        public DbSet<User> Users { get; set; }
        public DbSet<Note> Notes { get; set; }
        public DbSet<MediaFile> MediaFiles { get; set; }
        public DbSet<Tag> Tags { get; set; }
        public DbSet<NoteTag> NoteTags { get; set; }

        protected override void OnModelCreating(ModelBuilder modelBuilder)
        {
            base.OnModelCreating(modelBuilder);

            // Đổi tên bảng để khớp với tên trong PostgreSQL (chữ thường)
            modelBuilder.Entity<User>().ToTable("users");
            modelBuilder.Entity<Note>().ToTable("notes");
            modelBuilder.Entity<MediaFile>().ToTable("media_files");
            modelBuilder.Entity<Tag>().ToTable("tags");
            modelBuilder.Entity<NoteTag>().ToTable("note_tags");

            // Thiết lập khóa chính tổng hợp
            modelBuilder.Entity<NoteTag>()
                .HasKey(nt => new { nt.NoteId, nt.TagId });

            // Thiết lập quan hệ Note - NoteTag
            modelBuilder.Entity<NoteTag>()
                .HasOne(nt => nt.Note)
                .WithMany(n => n.NoteTags)
                .HasForeignKey(nt => nt.NoteId);

            // Thiết lập quan hệ Tag - NoteTag
            modelBuilder.Entity<NoteTag>()
                .HasOne(nt => nt.Tag)
                .WithMany(t => t.NoteTags)
                .HasForeignKey(nt => nt.TagId);
        }
    }
}
