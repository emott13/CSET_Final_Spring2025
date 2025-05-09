chatInput = document.getElementById("chat-message-input");
chatInput.focus();
msgContainer = document.getElementsByClassName("msg-container")[0];
msgContainer.scrollTop = msgContainer.scrollHeight;