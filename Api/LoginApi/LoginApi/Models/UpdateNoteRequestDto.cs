namespace LoginApi.Models
{
    public class UpdateNoteRequestDto
    {
        public string Title { get; set; } = string.Empty;
        public string Content { get; set; } = string.Empty;
        public List<string> Tags { get; set; } = new();
        public DateTime? ReminderAt { get; set; }
    }

}
