package com.example.bookorderapp.exceptions;

public class BookNotFoundException extends RuntimeException {
    public BookNotFoundException() {
        super();
    }
    public BookNotFoundException(String message) {
        super(message);
    }
    public BookNotFoundException(String message, Throwable cause) {
        super(message, cause);
    }
    // Optionally, more constructors if needed
}
