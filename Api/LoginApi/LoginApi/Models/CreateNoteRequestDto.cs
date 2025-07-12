namespace LoginApi.Models
{
    public class CreateNoteRequestDto
    {
        public Guid UserId { get; set; }
        public string Title { get; set; } = string.Empty;
        public string Content { get; set; } = string.Empty;
        public List<string> Tags { get; set; } = new();
    }
}
