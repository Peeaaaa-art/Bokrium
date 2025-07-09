class Books::RowsController < ApplicationController
  before_action :authenticate_user!
  before_action :set_book

  def show
    render partial: "bookshelf/b_note", locals: { book: @book }
  end

  def edit
    render partial: "bookshelf/b_note_row", formats: :html, locals: { book: @book }
  end

  def update
    index = params[:index].to_i
    if @book.update(book_params)
      flash.now[:row_update_success] = "『#{@book.title.truncate(20)}』を更新しました。"
      render partial: "bookshelf/b_note_row", formats: :html, locals: { book: @book, index: index }
    else
      render partial: "bookshelf/b_note_edit_row", locals: { book: @book, index: index }
    end
  end

  private

  def set_book
    @book = current_user.books.find(params[:book_id])
  end

  def book_params
    params.require(:book).permit(:title, :author, :publisher)
  end
end
