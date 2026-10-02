using System.Net;
using Microsoft.AspNetCore.Mvc.Testing;
using Xunit;

public class EndpointTests : IClassFixture<WebApplicationFactory<Program>>
{
    private readonly HttpClient _client;

    public EndpointTests(WebApplicationFactory<Program> factory) => _client = factory.CreateClient();

    [Fact]
    public async Task Health_returns_200()
    {
        var response = await _client.GetAsync("/health");
        Assert.Equal(HttpStatusCode.OK, response.StatusCode);
    }

    [Fact]
    public async Task Root_returns_hello()
    {
        var body = await _client.GetStringAsync("/");
        Assert.Contains("hello", body);
    }
}
