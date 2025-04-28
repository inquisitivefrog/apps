package com.example.bookorderapp.exceptions;

public class ErrorResponse {
    private String message;
    private Object details;

    public ErrorResponse(String message, Object details) {
        this.message = message;
        this.details = details;
    }

    // Getter for message
    public String getMessage() {
        return message;
    }

    // Setter for message
    public void setMessage(String message) {
        this.message = message;
    }

    // Getter for details
    public Object getDetails() {
        return details;
    }

    // Setter for details
    public void setDetails(Object details) {
        this.details = details;
    }
}
