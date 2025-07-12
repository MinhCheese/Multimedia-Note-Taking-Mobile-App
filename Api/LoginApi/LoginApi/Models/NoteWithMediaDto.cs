namespace LoginApi.Models
{
    public class NoteWithMediaDto
    {
        public Guid Id { get; set; }
        public string Title { get; set; } = "";
        public string Content { get; set; } = "";
        public List<string> Tags { get; set; } = new();
        public string? FileType { get; set; }  // "image", "audio", "video", hoặc null nếu không có
    }
}
