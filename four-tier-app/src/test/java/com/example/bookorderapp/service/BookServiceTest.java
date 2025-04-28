package com.example.bookorderapp.service;

import com.example.bookorderapp.BookOrderApplication;
import com.example.bookorderapp.exceptions.BookNotFoundException;
import com.example.bookorderapp.model.Book;
import com.example.bookorderapp.repository.BookRepository;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;

import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.boot.test.mock.mockito.MockBean;
import org.springframework.security.test.context.support.WithMockUser;

import java.math.BigDecimal;
import java.util.ArrayList;
import java.util.List;
import java.util.Optional;

import static org.junit.jupiter.api.Assertions.*;
import static org.mockito.Mockito.*;


@SpringBootTest(classes = BookOrderApplication.class)
public class BookServiceTest {

    @Autowired
    private BookService bookService;

    @MockBean
    private BookRepository bookRepository;
    
    private Book testBook;

    @BeforeEach
    void setUp() {
        testBook = new Book("Test Book", "Test Author", BigDecimal.valueOf(19.99));
    }        

    @Test
    @WithMockUser(username = "user", password = "password", roles = "USER")
    public void testGetAllBooks() {
        List<Book> books = new ArrayList<>();
        books.add(testBook);
        when(bookRepository.findAll()).thenReturn(books);

        List<Book> result = bookService.getAllBooks();

        assertEquals(1, result.size());
        assertEquals("Test Book", result.get(0).getTitle());
        verify(bookRepository, times(1)).findAll();
    }

    @Test
    @WithMockUser(username = "user", password = "password", roles = "USER")
    public void testGetBookById() {
        Long id = 1L;
        Book book = new Book("Test Book", "Test Author", new java.math.BigDecimal("19.99"));
        when(bookRepository.findById(id)).thenReturn(Optional.of(book));

        Book foundBook = bookService.getBookById(id);
        assertEquals(book.getTitle(), foundBook.getTitle());
        verify(bookRepository, times(1)).findById(1L);
    }

    @Test
    @WithMockUser(username = "user", password = "password", roles = "USER")
    public void testGetBookById_NotFound() {
        when(bookRepository.findById(1L)).thenReturn(Optional.empty());

        assertThrows(BookNotFoundException.class, () -> bookService.getBookById(1L));
        verify(bookRepository, times(1)).findById(1L);
    }

    @Test
    @WithMockUser(username = "user", password = "password", roles = "USER")
    public void testCreateBook() {
        when(bookRepository.save(testBook)).thenReturn(testBook);

        Book createdBook = bookService.createBook(testBook);

        assertEquals("Test Book", createdBook.getTitle());
        verify(bookRepository, times(1)).save(testBook);
    }
}
