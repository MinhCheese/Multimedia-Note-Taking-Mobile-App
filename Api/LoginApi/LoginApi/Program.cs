using Microsoft.EntityFrameworkCore;
using Microsoft.AspNetCore.Authentication.JwtBearer;
using Microsoft.IdentityModel.Tokens;
using System.Text;
using LoginApi.Data;
using LoginApi.Helpers;
using LoginApi.Data;
using System.IdentityModel.Tokens.Jwt;
using Microsoft.OpenApi.Models;
using Microsoft.OpenApi.Models;
using Swashbuckle.AspNetCore.SwaggerGen;
AppContext.SetSwitch("Npgsql.EnableLegacyTimestampBehavior", true);
var builder = WebApplication.CreateBuilder(args);

// 1. Add Controller + Swagger
builder.Services.AddControllers();
builder.Services.AddEndpointsApiExplorer();
builder.Services.AddSwaggerGen(c =>
{
    c.SwaggerDoc("v1", new OpenApiInfo { Title = "My API", Version = "v1" });

    
    c.OperationFilter<FileUploadOperation>();
});

// 2. CORS – Cho phép từ mọi nguồn (dùng khi gọi từ Flutter)
builder.Services.AddCors(options =>
{
    options.AddPolicy("AllowAll", policy =>
        policy.AllowAnyOrigin().AllowAnyMethod().AllowAnyHeader());
});

// 3. Kết nối DbContext với PostgreSQL
builder.Services.AddDbContext<AppDbContext>(options =>
    options.UseNpgsql(builder.Configuration.GetConnectionString("DefaultConnection")));

// 4. Cấu hình JWT Authentication
var jwtKey = builder.Configuration["Jwt:Key"];
var key = Encoding.ASCII.GetBytes(jwtKey);

builder.Services.AddAuthentication(options =>
{
    options.DefaultAuthenticateScheme = JwtBearerDefaults.AuthenticationScheme;
    options.DefaultChallengeScheme = JwtBearerDefaults.AuthenticationScheme;
})
.AddJwtBearer(options =>
{
    options.RequireHttpsMetadata = false;
    options.SaveToken = true;
    options.TokenValidationParameters = new TokenValidationParameters
    {
        ValidateIssuerSigningKey = true,
        IssuerSigningKey = new SymmetricSecurityKey(key),
        ValidateIssuer = false,
        ValidateAudience = false
    };
});

// 5. Thêm helper tạo JWT
builder.Services.AddSingleton(new JwtHelper(jwtKey));

var app = builder.Build();

if (app.Environment.IsDevelopment())
{
    app.UseSwagger();
    app.UseSwaggerUI();
}   

//app.UseHttpsRedirection();

// Bắt buộc thêm thứ tự: Authentication → Authorization
app.UseAuthentication();
app.UseAuthorization();

app.UseCors("AllowAll");
app.UseStaticFiles(new StaticFileOptions
{
    ServeUnknownFileTypes = true, // Cho phép phục vụ file có phần mở rộng chưa rõ
    DefaultContentType = "application/octet-stream",
    OnPrepareResponse = ctx =>
    {
        var path = ctx.File.Name;
        if (path.EndsWith(".aac", StringComparison.OrdinalIgnoreCase))
        {
            ctx.Context.Response.ContentType = "audio/aac"; // MIME type đúng
        }
    }
});

app.MapControllers();

app.Run();
public class FileUploadOperation : IOperationFilter
{
    public void Apply(OpenApiOperation operation, OperationFilterContext context)
    {
        // Nếu method có tham số kiểu IFormFile => bật hỗ trợ upload
        var hasFileParam = context.MethodInfo
            .GetParameters()
            .Any(p => p.ParameterType == typeof(IFormFile));

        if (hasFileParam)
        {
            operation.RequestBody = new OpenApiRequestBody
            {
                Content = {
                    ["multipart/form-data"] = new OpenApiMediaType
                    {
                        Schema = new OpenApiSchema
                        {
                            Type = "object",
                            Properties = {
                                ["file"] = new OpenApiSchema
                                {
                                    Type = "string",
                                    Format = "binary"
                                },
                                ["noteId"] = new OpenApiSchema
                                {
                                    Type = "string",
                                    Format = "uuid"
                                }
                            },
                            Required = { "file", "noteId" }
                        }
                    }
                }
            };
        }
    }
}
