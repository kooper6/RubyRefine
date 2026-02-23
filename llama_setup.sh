curl -fsSL https://ollama.com/install.sh | sh

killall Ollama
OLLAMA_HOST=127.0.0.1:11431 ollama pull llama3

killall Ollama
OLLAMA_HOST=127.0.0.1:11432 ollama pull mistral

killall Ollama
OLLAMA_HOST=127.0.0.1:11431 ollama pull llama3.1

killall Ollama

##
##in separate tabs for 3 models, or in separate tmux sessions
##

OLLAMA_HOST=127.0.0.1:11431 ollama serve
