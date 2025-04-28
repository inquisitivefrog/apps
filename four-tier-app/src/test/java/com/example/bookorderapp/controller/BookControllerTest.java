package com.example.bookorderapp.controller;


import com.example.bookorderapp.BookOrderApplication;
import com.example.bookorderapp.repository.BookRepository;
import com.example.bookorderapp.model.Book;
import com.fasterxml.jackson.databind.ObjectMapper;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.mockito.Mockito;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.autoconfigure.web.servlet.AutoConfigureMockMvc;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.boot.test.mock.mockito.MockBean;
import org.springframework.http.MediaType;
import org.springframework.security.test.context.support.WithMockUser;
import org.springframework.test.web.servlet.MockMvc;

import java.math.BigDecimal;
import java.util.Arrays;
import java.util.Optional;

import static org.mockito.Mockito.verify;
import static org.mockito.Mockito.times;
import static org.mockito.Mockito.any;
import static org.mockito.Mockito.*;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.*;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.*;

@SpringBootTest(webEnvironment = SpringBootTest.WebEnvironment.RANDOM_PORT, classes = BookOrderApplication.class)
@AutoConfigureMockMvc
public class BookControllerTest {

    @Autowired
    private MockMvc mockMvc;

    @Autowired
    private ObjectMapper objectMapper;

    @MockBean
    private BookRepository bookRepository;

    private Book testBook;

    @BeforeEach
    void setUp() {
        testBook = new Book("Test Book", "Test Author", BigDecimal.valueOf(19.99));
    }

    @Test
    @WithMockUser(username = "user", password = "password", roles = "USER")
    public void testListBooks() throws Exception {
        when(bookRepository.findAll()).thenReturn(Arrays.asList(testBook));

        mockMvc.perform(get("/books"))
                .andExpect(status().isOk())
                .andExpect(view().name("books/list"))
                .andExpect(model().attributeExists("books"));
    }

    @Test
    @WithMockUser(username = "user", password = "password", roles = "USER")
    public void testShowAddForm() throws Exception {
        mockMvc.perform(get("/books/add"))
                .andExpect(status().isOk())
                .andExpect(view().name("books/add"))
                .andExpect(model().attributeExists("book"));
    }

    @Test
    @WithMockUser(username = "user", password = "password", roles = "USER")
    public void testAddBook() throws Exception {
        Book book = new Book("Test Book", "Test Author", new java.math.BigDecimal("19.99"));

        mockMvc.perform(post("/books/add")
                .contentType(MediaType.APPLICATION_FORM_URLENCODED)
                .param("title", book.getTitle())
                .param("author", book.getAuthor())
                .param("price", book.getPrice().toString()))
               .andExpect(status().is3xxRedirection())
               .andExpect(redirectedUrl("/books"));

        verify(bookRepository, times(1)).save(any(Book.class));
    }

    @Test
    @WithMockUser(username = "user", password = "password", roles = "USER")
    public void testShowUpdateForm() throws Exception {
        when(bookRepository.findById(1L)).thenReturn(Optional.of(testBook));

        mockMvc.perform(get("/books/edit/1"))
                .andExpect(status().isOk())
                .andExpect(view().name("books/edit"))
                .andExpect(model().attributeExists("book"));
    }

    @Test
    @WithMockUser(username = "user", password = "password", roles = "USER")
    public void testUpdateBook() throws Exception {

        mockMvc.perform(post("/books/update/1")
                .param("title", "Updated Book")
                .param("author", "Updated Author"))
                .andExpect(status().is3xxRedirection())
                .andExpect(redirectedUrl("/books"));

        verify(bookRepository, times(1)).save(any(Book.class));
    }

    @Test
    @WithMockUser(username = "user", password = "password", roles = "USER")
    public void testDeleteBook() throws Exception {

        mockMvc.perform(get("/books/delete/1"))
                .andExpect(status().is3xxRedirection())
                .andExpect(redirectedUrl("/books"));
        verify(bookRepository, times(1)).deleteById(1L);
    }

    @Test
    @WithMockUser(username = "user", password = "password", roles = "USER")
    public void testNotFoundExceptionWhenEditingNonExistentBook() throws Exception {
        when(bookRepository.findById(1L)).thenReturn(Optional.empty());

        mockMvc.perform(get("/books/edit/1"))
                .andExpect(status().isNotFound());
    }

    @Test
    public void testUnauthorizedAccess() throws Exception {
        mockMvc.perform(get("/books"))
               .andExpect(status().isUnauthorized());
    }
}
