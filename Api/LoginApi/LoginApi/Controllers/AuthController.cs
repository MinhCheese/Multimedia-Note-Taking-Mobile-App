using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using LoginApi.Data;
using LoginApi.Models;
using LoginApi.Helpers;
using BCrypt.Net;

namespace LoginApi.Controllers
{
    [ApiController]
    [Route("api/[controller]")]
    public class AuthController : ControllerBase
    {
        private readonly AppDbContext _context;
        private readonly JwtHelper _jwtHelper;

        public AuthController(AppDbContext context, JwtHelper jwtHelper)
        {
            _context = context;
            _jwtHelper = jwtHelper;
        }

        [HttpPost("login")]
        public async Task<IActionResult> Login([FromBody] UserLoginDto loginDto)
        {
            var user = await _context.Users.FirstOrDefaultAsync(u => u.Email == loginDto.Email);
            if (user == null)
            {
                return Unauthorized(new { message = "Email không tồn tại." });
            }

            // So sánh mật khẩu
            if (!BCrypt.Net.BCrypt.Verify(loginDto.Password, user.PasswordHash))
            {
                return Unauthorized(new { message = "Sai mật khẩu." });
            }

            // Tạo JWT token
            var token = _jwtHelper.GenerateToken(user.Id, user.Email);

            return Ok(new
            {
                token,
                user = new { user.Id, user.Name, user.Email }
            });
        }


        [HttpPost("register")]
        public async Task<IActionResult> Register([FromBody] UserRegisterDto registerDto)
        {
            var existingUser = await _context.Users.FirstOrDefaultAsync(u => u.Email == registerDto.Email);
            if (existingUser != null)
            {
                return BadRequest(new { message = "Email đã tồn tại!" });
            }

            var hashedPassword = BCrypt.Net.BCrypt.HashPassword(registerDto.Password);

            var user = new User
            {
                Id = Guid.NewGuid(),
                Name = registerDto.Name,
                Email = registerDto.Email,
                PasswordHash = hashedPassword,
                CreatedAt = DateTime.UtcNow // vẫn nên gán rõ ràng
            };

            _context.Users.Add(user);
            await _context.SaveChangesAsync();

            return Ok(new
            {
                message = "Đăng ký thành công!",
                user = new
                {
                    id = user.Id,
                    name = user.Name,
                    email = user.Email
                }
            });
        }

    }
}
