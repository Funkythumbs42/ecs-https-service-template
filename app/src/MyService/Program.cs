var builder = WebApplication.CreateBuilder(args);

// Listen on 8080 (the port the ALB target group / ECS task definition expect).
// ASPNETCORE_HTTP_PORTS (set in the Dockerfile) can override this.
if (string.IsNullOrEmpty(builder.Configuration["ASPNETCORE_HTTP_PORTS"]) &&
    string.IsNullOrEmpty(builder.Configuration["ASPNETCORE_URLS"]))
{
    builder.WebHost.UseUrls("http://0.0.0.0:8080");
}

var app = builder.Build();

app.MapGet("/", () => Results.Text("hello from my-service\n"));
app.MapGet("/health", () => Results.Ok(new { status = "ok" }));

app.Run();

// Exposed so the test project can use WebApplicationFactory<Program>.
public partial class Program;
