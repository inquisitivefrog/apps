
sre@ubuntu:~$ curl http://localhost:8080/books
<!DOCTYPE html>
<html lang="en">
<head>
    <title>Book List</title>
</head>
<body>
    <h1>Books</h1>
    <a href="/books/add">Add New Book</a>
    <table>
        <tr>
            <th>Title</th>
            <th>Author</th>
            <th>Price</th>
            <th>Actions</th>
        </tr>
        
    </table>
</body>
</html>

sre@ubuntu:~$ curl http://localhost:8080/books/add
<!DOCTYPE html>
<html lang="en">
<head>
    <title>Add Book</title>
</head>
<body>
    <h1>Add a New Book</h1>
    <form action="/books/add" method="post">
        <label for="title">Title:</label>
        <input type="text" id="title" name="title" required>
        <br/>
        <label for="author">Author:</label>
        <input type="text" id="author" name="author" required>
        <br/>
        <label for="price">Price:</label>
        <input type="number" step="0.01" id="price" name="price" required>
        <br/>
        <button type="submit">Add Book</button>
    </form>
    <a href="/books">Back to List</a>
</body>
</html>

sre@ubuntu:~$ curl -X POST -d "title=NewBook&author=NewAuthor&price=19.99" http://localhost:8080/books/add
sre@ubuntu:~$ 

app logs
2025-02-14 00:09:45.643 [http-nio-8080-exec-1] INFO  o.s.web.servlet.DispatcherServlet - Completed initialization in 3 ms
2025-02-14 00:09:45.652 [http-nio-8080-exec-1] DEBUG o.s.web.servlet.DispatcherServlet - GET "/books", parameters={}
2025-02-14 00:09:45.662 [http-nio-8080-exec-1] DEBUG o.s.w.s.m.m.a.RequestMappingHandlerMapping - Mapped to com.example.bookorderapp.controller.BookController#listBooks(Model)
2025-02-14 00:09:45.868 [http-nio-8080-exec-1] DEBUG o.s.w.s.v.ContentNegotiatingViewResolver - Selected '*/*' given [*/*]
2025-02-14 00:09:46.091 [http-nio-8080-exec-1] DEBUG o.s.web.servlet.DispatcherServlet - Completed 200 OK
2025-02-14 00:10:33.040 [http-nio-8080-exec-2] DEBUG o.s.web.servlet.DispatcherServlet - GET "/books/add", parameters={}
2025-02-14 00:10:33.041 [http-nio-8080-exec-2] DEBUG o.s.w.s.m.m.a.RequestMappingHandlerMapping - Mapped to com.example.bookorderapp.controller.BookController#showAddForm(Model)
2025-02-14 00:10:33.050 [http-nio-8080-exec-2] DEBUG o.s.w.s.v.ContentNegotiatingViewResolver - Selected '*/*' given [*/*]
2025-02-14 00:10:33.144 [http-nio-8080-exec-2] DEBUG o.s.web.servlet.DispatcherServlet - Completed 200 OK
2025-02-14 00:13:54.924 [http-nio-8080-exec-3] DEBUG o.s.web.servlet.DispatcherServlet - POST "/books/add", parameters={masked}
2025-02-14 00:13:54.925 [http-nio-8080-exec-3] DEBUG o.s.w.s.m.m.a.RequestMappingHandlerMapping - Mapped to com.example.bookorderapp.controller.BookController#addBook(Book)
2025-02-14 00:13:55.038 [http-nio-8080-exec-3] DEBUG o.s.web.servlet.view.RedirectView - View name [redirect:], model {}
2025-02-14 00:13:55.040 [http-nio-8080-exec-3] DEBUG o.s.web.servlet.DispatcherServlet - Completed 302 FOUND
