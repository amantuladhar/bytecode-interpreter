#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <ctype.h>

// Token types
typedef enum {
    TOKEN_EOF,
    TOKEN_NUMBER,
    TOKEN_PLUS,
    TOKEN_MINUS,
    TOKEN_MULTIPLY,
    TOKEN_DIVIDE,
    TOKEN_LPAREN,
    TOKEN_RPAREN
} TokenType;

// Token structure
typedef struct {
    TokenType type;
    int value;  // Used for numbers
} Token;

// Parser state
typedef struct {
    const char* input;
    int position;
    Token current_token;
} Parser;

// Function declarations
static Token get_next_token(Parser* parser);
static int expression(Parser* parser, int rbp);
static int nud(Parser* parser, Token token);
static int led(Parser* parser, Token token, int left);

// Initialize parser
void parser_init(Parser* parser, const char* input) {
    parser->input = input;
    parser->position = 0;
    parser->current_token = get_next_token(parser);
}

// Tokenizer
static Token get_next_token(Parser* parser) {
    Token token;
    
    // Skip whitespace
    while (parser->input[parser->position] == ' ')
        parser->position++;
    
    // Check for end of input
    if (parser->input[parser->position] == '\0') {
        token.type = TOKEN_EOF;
        return token;
    }
    
    // Parse numbers
    if (isdigit(parser->input[parser->position])) {
        token.type = TOKEN_NUMBER;
        token.value = 0;
        while (isdigit(parser->input[parser->position])) {
            token.value = token.value * 10 + (parser->input[parser->position] - '0');
            parser->position++;
        }
        return token;
    }
    
    // Parse operators
    switch (parser->input[parser->position]) {
        case '+':
            token.type = TOKEN_PLUS;
            break;
        case '-':
            token.type = TOKEN_MINUS;
            break;
        case '*':
            token.type = TOKEN_MULTIPLY;
            break;
        case '/':
            token.type = TOKEN_DIVIDE;
            break;
        case '(':
            token.type = TOKEN_LPAREN;
            break;
        case ')':
            token.type = TOKEN_RPAREN;
            break;
        default:
            printf("Invalid character: %c\n", parser->input[parser->position]);
            exit(1);
    }
    
    parser->position++;
    return token;
}

// Get operator precedence
static int get_precedence(TokenType type) {
    switch (type) {
        case TOKEN_PLUS:
        case TOKEN_MINUS:
            return 10;
        case TOKEN_MULTIPLY:
        case TOKEN_DIVIDE:
            return 20;
        default:
            return 0;
    }
}

// Advance to next token
static void advance(Parser* parser) {
    parser->current_token = get_next_token(parser);
}

// Parse expression
static int expression(Parser* parser, int rbp) {
    Token token = parser->current_token;
    advance(parser);
    
    int left = nud(parser, token);
    
    while (rbp < get_precedence(parser->current_token.type)) {
        token = parser->current_token;
        advance(parser);
        left = led(parser, token, left);
    }
    
    return left;
}

// Parse prefix expressions (numbers and parentheses)
static int nud(Parser* parser, Token token) {
    switch (token.type) {
        case TOKEN_NUMBER:
            return token.value;
        case TOKEN_LPAREN: {
            int value = expression(parser, 0);
            if (parser->current_token.type != TOKEN_RPAREN) {
                printf("Expected closing parenthesis\n");
                exit(1);
            }
            advance(parser);
            return value;
        }
        default:
            printf("Unexpected token in nud\n");
            exit(1);
    }
}

// Parse infix expressions (operators)
static int led(Parser* parser, Token token, int left) {
    switch (token.type) {
        case TOKEN_PLUS:
            return left + expression(parser, get_precedence(TOKEN_PLUS));
        case TOKEN_MINUS:
            return left - expression(parser, get_precedence(TOKEN_MINUS));
        case TOKEN_MULTIPLY:
            return left * expression(parser, get_precedence(TOKEN_MULTIPLY));
        case TOKEN_DIVIDE: {
            int right = expression(parser, get_precedence(TOKEN_DIVIDE));
            if (right == 0) {
                printf("Division by zero\n");
                exit(1);
            }
            return left / right;
        }
        default:
            printf("Unexpected token in led\n");
            exit(1);
    }
}

// Parse and evaluate an expression
int parse(const char* input) {
    Parser parser;
    parser_init(&parser, input);
    int result = expression(&parser, 0);
    
    if (parser.current_token.type != TOKEN_EOF) {
        printf("Unexpected tokens at end of input\n");
        exit(1);
    }
    
    return result;
}

// Example usage
int main() {
    const char* expressions[] = {
        "3 + 4 * 2",
        "1 + 2 + 3",
        "10 - 5 * 2",
        "(3 + 4) * 2",
        "8 / 4 + 2"
    };
    
    for (int i = 0; i < sizeof(expressions) / sizeof(expressions[0]); i++) {
        printf("Expression: %s\n", expressions[i]);
        printf("Result: %d\n\n", parse(expressions[i]));
    }
    
    return 0;
}
