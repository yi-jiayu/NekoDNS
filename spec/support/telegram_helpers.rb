def text_message(params)
  {
    message: {
      text: params[:text],
      from: {
        id: params[:from_id],
      },
      chat: {
        id: params[:chat_id],
      },
    },
  }
end