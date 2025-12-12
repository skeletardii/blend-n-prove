extends Node

## OpenRouter Service Proxy
## This is a proxy autoload that forwards calls to OpenRouterServiceImpl
## Following the proxy pattern used in this project

signal response_received(content: String)
signal error_occurred(error_message: String)

var _impl: Node = null

func _ready() -> void:
	# Implementation will be loaded by ManagerBootstrap
	pass

func _set_impl(impl: Node) -> void:
	_impl = impl
	# Forward signals
	if _impl.response_received.connect(_on_response_received) != OK:
		print("Warning: Could not connect response_received signal")
	if _impl.error_occurred.connect(_on_error_occurred) != OK:
		print("Warning: Could not connect error_occurred signal")

func _on_response_received(content: String) -> void:
	response_received.emit(content)

func _on_error_occurred(error_message: String) -> void:
	error_occurred.emit(error_message)

## Send a chat completion request to OpenRouter API
## @param messages: Array of message dictionaries with 'role' and 'content' keys
## @param http_request: HTTPRequest node to use for the request
## @return: String containing the AI response content, or empty string on error
func send_chat_request(messages: Array, http_request: HTTPRequest) -> String:
	if _impl:
		return await _impl.send_chat_request(messages, http_request)
	print("Error: OpenRouterService implementation not loaded")
	return ""
