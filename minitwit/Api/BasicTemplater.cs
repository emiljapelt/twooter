using System.Collections.Generic;
using Shared;
using System.Text;
using System.Linq;
using System;

namespace Api
{
    public class BasicTemplater
    {
        public static string GenerateTimeline(List<MessageReadDTO> messages, bool loggedin)
        {
            messages.Sort((x, y) => DateTime.Compare(x.pub_date, y.pub_date));
            messages.Reverse();

            StringBuilder sb = new StringBuilder();
            sb.Append("<html>");
            if(loggedin) sb.Append("<form method=post action=add_message><input name=Text><input type=submit></form>");
            foreach(MessageReadDTO msg in messages) 
            {
                sb.Append($"<p>{msg.author.username} [{msg.pub_date}]: {msg.text}</p>");
                if(loggedin) sb.Append($"<form method=post action={msg.author.username}/follow><button type=submit>Follow</button></form>");
            }
            sb.Append("</html>");
            return sb.ToString();
        }

        public static string GenerateLoginPage()
        {
            return @"<form method=post action=login>
                    <input name=Username>
                    <input name=Password>
                    <input type=submit>
                    </form>";
        }

        public static string GenerateRegisterPage()
        {
            return @"<form method=post action=register>
                    <input name=Username>
                    <input name=Email>
                    <input name=Password1>
                    <input name=Password2>
                    <input type=submit>
                    </form>";
        }
    }
}