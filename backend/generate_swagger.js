const fs = require('fs');
const path = require('path');

const swaggerObj = {
  "swagger": "2.0",
  "info": {
    "description": "Backend API for RockyDex Mobile App, supporting user authentication, favorites, and reading history synchronization.",
    "title": "RockyDex API",
    "contact": {},
    "version": "1.1.2"
  },
  "host": "localhost:8080",
  "basePath": "/api",
  "securityDefinitions": {
    "BearerAuth": {
      "type": "apiKey",
      "name": "Authorization",
      "in": "header"
    }
  },
  "paths": {
    "/auth/register": {
      "post": {
        "description": "Creates a new user account with email, name, and password.",
        "consumes": ["application/json"],
        "produces": ["application/json"],
        "tags": ["auth"],
        "summary": "Register a new user",
        "parameters": [
          {
            "description": "Registration details",
            "name": "input",
            "in": "body",
            "required": true,
            "schema": {
              "$ref": "#/definitions/dto.RegisterInput"
            }
          }
        ],
        "responses": {
          "201": {
            "description": "Created",
            "schema": {
              "$ref": "#/definitions/dto.AuthResponse"
            }
          },
          "400": {
            "description": "Bad Request",
            "schema": {
              "type": "object",
              "additionalProperties": { "type": "string" }
            }
          },
          "409": {
            "description": "Conflict - Email already registered",
            "schema": {
              "type": "object",
              "additionalProperties": { "type": "string" }
            }
          }
        }
      }
    },
    "/auth/login": {
      "post": {
        "description": "Authenticates a user with email and password, returning a JWT token.",
        "consumes": ["application/json"],
        "produces": ["application/json"],
        "tags": ["auth"],
        "summary": "User Login",
        "parameters": [
          {
            "description": "Login Credentials",
            "name": "input",
            "in": "body",
            "required": true,
            "schema": {
              "$ref": "#/definitions/dto.LoginInput"
            }
          }
        ],
        "responses": {
          "200": {
            "description": "OK",
            "schema": {
              "$ref": "#/definitions/dto.AuthResponse"
            }
          },
          "400": {
            "description": "Bad Request",
            "schema": {
              "type": "object",
              "additionalProperties": { "type": "string" }
            }
          },
          "401": {
            "description": "Unauthorized",
            "schema": {
              "type": "object",
              "additionalProperties": { "type": "string" }
            }
          }
        }
      }
    },
    "/auth/google": {
      "post": {
        "description": "Authenticates a user using a Google Identity Token. Registers them if not already registered.",
        "consumes": ["application/json"],
        "produces": ["application/json"],
        "tags": ["auth"],
        "summary": "Google Authentication Login",
        "parameters": [
          {
            "description": "Google ID Token",
            "name": "input",
            "in": "body",
            "required": true,
            "schema": {
              "$ref": "#/definitions/dto.GoogleLoginInput"
            }
          }
        ],
        "responses": {
          "200": {
            "description": "OK",
            "schema": {
              "$ref": "#/definitions/dto.AuthResponse"
            }
          },
          "400": {
            "description": "Bad Request",
            "schema": {
              "type": "object",
              "additionalProperties": { "type": "string" }
            }
          },
          "401": {
            "description": "Unauthorized",
            "schema": {
              "type": "object",
              "additionalProperties": { "type": "string" }
            }
          }
        }
      }
    },
    "/auth/forgot-password": {
      "post": {
        "description": "Generates a 6-digit password reset PIN for the given email. Logs and returns the code (dev-only fallback).",
        "consumes": ["application/json"],
        "produces": ["application/json"],
        "tags": ["auth"],
        "summary": "Request Password Reset Code",
        "parameters": [
          {
            "description": "User Email",
            "name": "input",
            "in": "body",
            "required": true,
            "schema": {
              "$ref": "#/definitions/dto.ForgotPasswordInput"
            }
          }
        ],
        "responses": {
          "200": {
            "description": "Reset PIN requested",
            "schema": {
              "type": "object",
              "additionalProperties": { "type": "string" }
            }
          },
          "400": {
            "description": "Bad Request",
            "schema": {
              "type": "object",
              "additionalProperties": { "type": "string" }
            }
          },
          "500": {
            "description": "Internal Server Error",
            "schema": {
              "type": "object",
              "additionalProperties": { "type": "string" }
            }
          }
        }
      }
    },
    "/auth/reset-password": {
      "post": {
        "description": "Resets the user's password using the 6-digit token code received.",
        "consumes": ["application/json"],
        "produces": ["application/json"],
        "tags": ["auth"],
        "summary": "Reset User Password",
        "parameters": [
          {
            "description": "Reset details (Email, Token, and New Password)",
            "name": "input",
            "in": "body",
            "required": true,
            "schema": {
              "$ref": "#/definitions/dto.ResetPasswordInput"
            }
          }
        ],
        "responses": {
          "200": {
            "description": "Password reset successfully",
            "schema": {
              "type": "object",
              "additionalProperties": { "type": "string" }
            }
          },
          "400": {
            "description": "Bad Request / Invalid token / Expired",
            "schema": {
              "type": "object",
              "additionalProperties": { "type": "string" }
            }
          }
        }
      }
    },
    "/user/profile": {
      "get": {
        "security": [{ "BearerAuth": [] }],
        "description": "Returns the user's profile information including preferences.",
        "produces": ["application/json"],
        "tags": ["user"],
        "summary": "Get user profile",
        "responses": {
          "200": {
            "description": "OK",
            "schema": {
              "$ref": "#/definitions/domain.User"
            }
          },
          "401": {
            "description": "Unauthorized",
            "schema": {
              "type": "object",
              "additionalProperties": { "type": "string" }
            }
          },
          "500": {
            "description": "Internal Server Error",
            "schema": {
              "type": "object",
              "additionalProperties": { "type": "string" }
            }
          }
        }
      },
      "put": {
        "security": [{ "BearerAuth": [] }],
        "description": "Updates user profile avatar, theme, layout, or brightness settings.",
        "consumes": ["application/json"],
        "produces": ["application/json"],
        "tags": ["user"],
        "summary": "Update user profile preferences",
        "parameters": [
          {
            "description": "Profile details to update",
            "name": "input",
            "in": "body",
            "required": true,
            "schema": {
              "$ref": "#/definitions/dto.UpdateProfileInput"
            }
          }
        ],
        "responses": {
          "200": {
            "description": "OK",
            "schema": {
              "$ref": "#/definitions/domain.Profile"
            }
          },
          "400": {
            "description": "Bad Request",
            "schema": {
              "type": "object",
              "additionalProperties": { "type": "string" }
            }
          },
          "401": {
            "description": "Unauthorized",
            "schema": {
              "type": "object",
              "additionalProperties": { "type": "string" }
            }
          },
          "500": {
            "description": "Internal Server Error",
            "schema": {
              "type": "object",
              "additionalProperties": { "type": "string" }
            }
          }
        }
      }
    },
    "/user/stats": {
      "get": {
        "security": [{ "BearerAuth": [] }],
        "description": "Returns counts of read comics, favorites, and chapters read.",
        "produces": ["application/json"],
        "tags": ["user"],
        "summary": "Get user reading statistics",
        "responses": {
          "200": {
            "description": "OK",
            "schema": {
              "$ref": "#/definitions/dto.ReadingStats"
            }
          },
          "401": {
            "description": "Unauthorized",
            "schema": {
              "type": "object",
              "additionalProperties": { "type": "string" }
            }
          },
          "500": {
            "description": "Internal Server Error",
            "schema": {
              "type": "object",
              "additionalProperties": { "type": "string" }
            }
          }
        }
      }
    },
    "/favorites": {
      "get": {
        "security": [{ "BearerAuth": [] }],
        "description": "Returns a list of all comics marked as favorite by the logged-in user.",
        "produces": ["application/json"],
        "tags": ["library"],
        "summary": "Get user's favorite comics list",
        "responses": {
          "200": {
            "description": "OK",
            "schema": {
              "type": "array",
              "items": {
                "$ref": "#/definitions/domain.Favorite"
              }
            }
          },
          "401": {
            "description": "Unauthorized",
            "schema": {
              "type": "object",
              "additionalProperties": { "type": "string" }
            }
          },
          "500": {
            "description": "Internal Server Error",
            "schema": {
              "type": "object",
              "additionalProperties": { "type": "string" }
            }
          }
        }
      },
      "post": {
        "security": [{ "BearerAuth": [] }],
        "description": "Marks a comic as favorite.",
        "consumes": ["application/json"],
        "produces": ["application/json"],
        "tags": ["library"],
        "summary": "Add a comic to user's favorites",
        "parameters": [
          {
            "description": "Favorite comic details",
            "name": "input",
            "in": "body",
            "required": true,
            "schema": {
              "$ref": "#/definitions/domain.Favorite"
            }
          }
        ],
        "responses": {
          "200": {
            "description": "Added to favorites",
            "schema": {
              "type": "object",
              "additionalProperties": { "type": "string" }
            }
          },
          "400": {
            "description": "Bad Request",
            "schema": {
              "type": "object",
              "additionalProperties": { "type": "string" }
            }
          },
          "401": {
            "description": "Unauthorized",
            "schema": {
              "type": "object",
              "additionalProperties": { "type": "string" }
            }
          },
          "500": {
            "description": "Internal Server Error",
            "schema": {
              "type": "object",
              "additionalProperties": { "type": "string" }
            }
          }
        }
      }
    },
    "/favorites/{slug}": {
      "delete": {
        "security": [{ "BearerAuth": [] }],
        "description": "Unmarks a comic as favorite by its slug.",
        "produces": ["application/json"],
        "tags": ["library"],
        "summary": "Remove a comic from user's favorites",
        "parameters": [
          {
            "type": "string",
            "description": "Comic Slug",
            "name": "slug",
            "in": "path",
            "required": true
          }
        ],
        "responses": {
          "200": {
            "description": "Removed from favorites",
            "schema": {
              "type": "object",
              "additionalProperties": { "type": "string" }
            }
          },
          "400": {
            "description": "Bad Request",
            "schema": {
              "type": "object",
              "additionalProperties": { "type": "string" }
            }
          },
          "401": {
            "description": "Unauthorized",
            "schema": {
              "type": "object",
              "additionalProperties": { "type": "string" }
            }
          },
          "500": {
            "description": "Internal Server Error",
            "schema": {
              "type": "object",
              "additionalProperties": { "type": "string" }
            }
          }
        }
      }
    },
    "/favorites/check/{slug}": {
      "get": {
        "security": [{ "BearerAuth": [] }],
        "description": "Checks if the user has favorited a comic.",
        "produces": ["application/json"],
        "tags": ["library"],
        "summary": "Check if a comic is in user's favorites",
        "parameters": [
          {
            "type": "string",
            "description": "Comic Slug",
            "name": "slug",
            "in": "path",
            "required": true
          }
        ],
        "responses": {
          "200": {
            "description": "is_favorite status",
            "schema": {
              "type": "object",
              "additionalProperties": { "type": "boolean" }
            }
          },
          "400": {
            "description": "Bad Request",
            "schema": {
              "type": "object",
              "additionalProperties": { "type": "string" }
            }
          },
          "401": {
            "description": "Unauthorized",
            "schema": {
              "type": "object",
              "additionalProperties": { "type": "string" }
            }
          },
          "500": {
            "description": "Internal Server Error",
            "schema": {
              "type": "object",
              "additionalProperties": { "type": "string" }
            }
          }
        }
      }
    },
    "/history": {
      "get": {
        "security": [{ "BearerAuth": [] }],
        "description": "Returns the chronological list of comics and chapters the user has read.",
        "produces": ["application/json"],
        "tags": ["library"],
        "summary": "Get user's reading history",
        "responses": {
          "200": {
            "description": "OK",
            "schema": {
              "type": "array",
              "items": {
                "$ref": "#/definitions/domain.History"
              }
            }
          },
          "401": {
            "description": "Unauthorized",
            "schema": {
              "type": "object",
              "additionalProperties": { "type": "string" }
            }
          },
          "500": {
            "description": "Internal Server Error",
            "schema": {
              "type": "object",
              "additionalProperties": { "type": "string" }
            }
          }
        }
      },
      "post": {
        "security": [{ "BearerAuth": [] }],
        "description": "Saves or updates reading history and chapter progress for a comic.",
        "consumes": ["application/json"],
        "produces": ["application/json"],
        "tags": ["library"],
        "summary": "Save reading history progress",
        "parameters": [
          {
            "description": "History details",
            "name": "input",
            "in": "body",
            "required": true,
            "schema": {
              "$ref": "#/definitions/domain.History"
            }
          }
        ],
        "responses": {
          "200": {
            "description": "History saved",
            "schema": {
              "type": "object",
              "additionalProperties": { "type": "string" }
            }
          },
          "400": {
            "description": "Bad Request",
            "schema": {
              "type": "object",
              "additionalProperties": { "type": "string" }
            }
          },
          "401": {
            "description": "Unauthorized",
            "schema": {
              "type": "object",
              "additionalProperties": { "type": "string" }
            }
          },
          "500": {
            "description": "Internal Server Error",
            "schema": {
              "type": "object",
              "additionalProperties": { "type": "string" }
            }
          }
        }
      },
      "delete": {
        "security": [{ "BearerAuth": [] }],
        "description": "Deletes all reading history records for the user.",
        "produces": ["application/json"],
        "tags": ["library"],
        "summary": "Clear all reading history",
        "responses": {
          "200": {
            "description": "History cleared",
            "schema": {
              "type": "object",
              "additionalProperties": { "type": "string" }
            }
          },
          "401": {
            "description": "Unauthorized",
            "schema": {
              "type": "object",
              "additionalProperties": { "type": "string" }
            }
          },
          "500": {
            "description": "Internal Server Error",
            "schema": {
              "type": "object",
              "additionalProperties": { "type": "string" }
            }
          }
        }
      }
    },
    "/history/{slug}": {
      "delete": {
        "security": [{ "BearerAuth": [] }],
        "description": "Deletes the user's reading history for a single comic.",
        "produces": ["application/json"],
        "tags": ["library"],
        "summary": "Delete reading history for a specific comic",
        "parameters": [
          {
            "type": "string",
            "description": "Comic Slug",
            "name": "slug",
            "in": "path",
            "required": true
          }
        ],
        "responses": {
          "200": {
            "description": "History deleted",
            "schema": {
              "type": "object",
              "additionalProperties": { "type": "string" }
            }
          },
          "400": {
            "description": "Bad Request",
            "schema": {
              "type": "object",
              "additionalProperties": { "type": "string" }
            }
          },
          "401": {
            "description": "Unauthorized",
            "schema": {
              "type": "object",
              "additionalProperties": { "type": "string" }
            }
          },
          "500": {
            "description": "Internal Server Error",
            "schema": {
              "type": "object",
              "additionalProperties": { "type": "string" }
            }
          }
        }
      }
    },
    "/history/comic/{slug}": {
      "get": {
        "security": [{ "BearerAuth": [] }],
        "description": "Returns the reading history for a specific comic if it exists.",
        "produces": ["application/json"],
        "tags": ["library"],
        "summary": "Get reading history for a specific comic",
        "parameters": [
          {
            "type": "string",
            "description": "Comic Slug",
            "name": "slug",
            "in": "path",
            "required": true
          }
        ],
        "responses": {
          "200": {
            "description": "OK",
            "schema": {
              "$ref": "#/definitions/domain.History"
            }
          },
          "400": {
            "description": "Bad Request",
            "schema": {
              "type": "object",
              "additionalProperties": { "type": "string" }
            }
          },
          "401": {
            "description": "Unauthorized",
            "schema": {
              "type": "object",
              "additionalProperties": { "type": "string" }
            }
          },
          "404": {
            "description": "Not Found",
            "schema": {
              "type": "object",
              "additionalProperties": { "type": "string" }
            }
          },
          "500": {
            "description": "Internal Server Error",
            "schema": {
              "type": "object",
              "additionalProperties": { "type": "string" }
            }
          }
        }
      }
    }
  },
  "definitions": {
    "dto.RegisterInput": {
      "type": "object",
      "required": ["email", "password", "name"],
      "properties": {
        "email": { "type": "string" },
        "password": { "type": "string" },
        "name": { "type": "string" }
      }
    },
    "dto.LoginInput": {
      "type": "object",
      "required": ["email", "password"],
      "properties": {
        "email": { "type": "string" },
        "password": { "type": "string" }
      }
    },
    "dto.GoogleLoginInput": {
      "type": "object",
      "required": ["id_token"],
      "properties": {
        "id_token": { "type": "string" }
      }
    },
    "dto.ForgotPasswordInput": {
      "type": "object",
      "required": ["email"],
      "properties": {
        "email": { "type": "string" }
      }
    },
    "dto.ResetPasswordInput": {
      "type": "object",
      "required": ["email", "token", "new_password"],
      "properties": {
        "email": { "type": "string" },
        "token": { "type": "string" },
        "new_password": { "type": "string" }
      }
    },
    "dto.AuthResponse": {
      "type": "object",
      "properties": {
        "token": { "type": "string" },
        "user": { "$ref": "#/definitions/domain.User" }
      }
    },
    "dto.UpdateProfileInput": {
      "type": "object",
      "properties": {
        "avatar_url": { "type": "string" },
        "theme_preference": { "type": "string" },
        "reading_layout": { "type": "string" },
        "reading_brightness": { "type": "number" }
      }
    },
    "dto.ReadingStats": {
      "type": "object",
      "properties": {
        "total_comics_read": { "type": "integer" },
        "total_favorites": { "type": "integer" },
        "chapters_read": { "type": "integer" }
      }
    },
    "domain.User": {
      "type": "object",
      "properties": {
        "id": { "type": "string" },
        "email": { "type": "string" },
        "name": { "type": "string" },
        "created_at": { "type": "string" },
        "updated_at": { "type": "string" },
        "profile": { "$ref": "#/definitions/domain.Profile" }
      }
    },
    "domain.Profile": {
      "type": "object",
      "properties": {
        "user_id": { "type": "string" },
        "avatar_url": { "type": "string" },
        "theme_preference": { "type": "string" },
        "reading_layout": { "type": "string" },
        "reading_brightness": { "type": "number" },
        "created_at": { "type": "string" },
        "updated_at": { "type": "string" }
      }
    },
    "domain.Favorite": {
      "type": "object",
      "properties": {
        "id": { "type": "integer" },
        "user_id": { "type": "string" },
        "comic_slug": { "type": "string" },
        "comic_name": { "type": "string" },
        "comic_thumb": { "type": "string" },
        "created_at": { "type": "string" }
      }
    },
    "domain.History": {
      "type": "object",
      "properties": {
        "id": { "type": "integer" },
        "user_id": { "type": "string" },
        "comic_slug": { "type": "string" },
        "comic_name": { "type": "string" },
        "comic_thumb": { "type": "string" },
        "chapter_slug": { "type": "string" },
        "chapter_name": { "type": "string" },
        "progress_percent": { "type": "integer" },
        "last_read_at": { "type": "string" }
      }
    }
  }
};

const jsonStr = JSON.stringify(swaggerObj, null, 2);

// Simple JSON to YAML converter
function jsonToYaml(obj, indent = 0) {
  let yaml = '';
  const spaces = ' '.repeat(indent);

  if (typeof obj !== 'object' || obj === null) {
    if (typeof obj === 'string') {
      if (obj.includes('\n') || obj.includes(':') || obj.includes('"')) {
        return `"${obj.replace(/"/g, '\\"')}"`;
      }
      return obj;
    }
    return String(obj);
  }

  if (Array.isArray(obj)) {
    if (obj.length === 0) return '[]';
    for (const val of obj) {
      const formattedVal = jsonToYaml(val, indent + 2);
      if (typeof val === 'object' && val !== null && !Array.isArray(val)) {
        // Multi-line object inside array
        const lines = formattedVal.split('\n');
        yaml += `\n${spaces}- ${lines[0].trim()}`;
        for (let i = 1; i < lines.length; i++) {
          yaml += `\n  ${spaces}${lines[i]}`;
        }
      } else {
        yaml += `\n${spaces}- ${formattedVal.trim()}`;
      }
    }
    return yaml;
  }

  const keys = Object.keys(obj);
  if (keys.length === 0) return '{}';
  
  for (let i = 0; i < keys.length; i++) {
    const key = keys[i];
    const val = obj[key];
    const prefix = i === 0 && indent > 0 ? '' : spaces;
    
    if (typeof val === 'object' && val !== null) {
      if (Array.isArray(val) && val.length === 0) {
        yaml += `${prefix}${key}: []\n`;
      } else if (!Array.isArray(val) && Object.keys(val).length === 0) {
        yaml += `${prefix}${key}: {}\n`;
      } else {
        yaml += `${prefix}${key}:\n`;
        const inner = jsonToYaml(val, indent + 2);
        yaml += inner.endsWith('\n') ? inner : inner + '\n';
      }
    } else {
      yaml += `${prefix}${key}: ${jsonToYaml(val)}\n`;
    }
  }
  return yaml;
}

const yamlStr = jsonToYaml(swaggerObj);

const docsGoStr = `// Package docs Code generated by swaggo/swag. DO NOT EDIT
package docs

import "github.com/swaggo/swag"

const docTemplate = \`{
    "schemes": {{ marshal .Schemes }},
    "swagger": "2.0",
    "info": {
        "description": "{{escape .Description}}",
        "title": "{{.Title}}",
        "contact": {},
        "version": "{{.Version}}"
    },
    "host": "{{.Host}}",
    "basePath": "{{.BasePath}}",
    "paths": ${JSON.stringify(swaggerObj.paths, null, 8).trim()},
    "definitions": ${JSON.stringify(swaggerObj.definitions, null, 8).trim()}
}\`

// SwaggerInfo holds exported Swagger Info so clients can modify it
var SwaggerInfo = &swag.Spec{
	Version:          "1.1.2",
	Host:             "localhost:8080",
	BasePath:         "/api",
	Schemes:          []string{},
	Title:            "RockyDex API",
	Description:      "Backend API for RockyDex Mobile App, supporting user authentication, favorites, and reading history synchronization.",
	InfoInstanceName: "swagger",
	SwaggerTemplate:  docTemplate,
	LeftDelim:        "{{",
	RightDelim:       "}}",
}

func init() {
	swag.Register(SwaggerInfo.InstanceName(), SwaggerInfo)
}
`;

const docsDir = path.join(__dirname, 'docs');
if (!fs.existsSync(docsDir)) {
  fs.mkdirSync(docsDir);
}

fs.writeFileSync(path.join(docsDir, 'swagger.json'), jsonStr, 'utf8');
fs.writeFileSync(path.join(docsDir, 'swagger.yaml'), yamlStr, 'utf8');
fs.writeFileSync(path.join(docsDir, 'docs.go'), docsGoStr, 'utf8');

console.log('Swagger documentation files generated successfully in backend/docs/ directory.');
