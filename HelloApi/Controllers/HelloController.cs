using Microsoft.AspNetCore.Mvc;
using HelloApi.Models;

namespace HelloApi.Controllers
{
    [Route("api/[controller]")]
    [ApiController]
    public class HelloController : ControllerBase
    {
        [HttpGet]
        public ActionResult<HelloModel> Get()
        {
            var helloMessage = new HelloModel
            {
                Message = "Hello, World!"
            };
            return Ok(helloMessage);
        }
    }
}
