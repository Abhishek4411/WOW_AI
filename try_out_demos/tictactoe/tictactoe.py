import customtkinter as ctk

class TicTacToe(ctk.CTk):
    def __init__(self):
        super().__init__()
        self.title("Neon Tic Tac Toe")
        self.geometry("400x450")
        self.configure(bg="#121212")
        
        ctk.set_appearance_mode("dark")
        ctk.set_default_color_theme("dark-blue")

        self.board = [None] * 9
        self.current_player = "X"
        self.buttons = []

        self.create_widgets()

    def create_widgets(self):
        self.label = ctk.CTkLabel(self, text="Tic Tac Toe", font=("Arial", 24), fg_color=None)
        self.label.pack(pady=20)

        frame = ctk.CTkFrame(self, fg_color="#1f1f1f")
        frame.pack(pady=10)

        for i in range(9):
            btn = ctk.CTkButton(frame, text="", width=80, height=80, corner_radius=20, fg_color="#121212", hover_color="#0f7ce3",
                                 font=("Arial", 20, "bold"), command=lambda i=i: self.make_move(i))
            btn.grid(row=i // 3, column=i % 3, padx=5, pady=5)
            self.buttons.append(btn)

        self.restart_btn = ctk.CTkButton(self, text="Restart", width=100, corner_radius=20, fg_color="#0f7ce3", hover_color="#00f0ff", command=self.restart)
        self.restart_btn.pack(pady=20)

    def make_move(self, index):
        if not self.buttons[index].cget("text") and not self.check_winner():
            self.buttons[index].configure(text=self.current_player)
            self.board[index] = self.current_player
            if self.check_winner():
                self.label.configure(text=f"Player {self.current_player} wins!")
                self.disable_buttons()
            elif None not in self.board:
                self.label.configure(text="It's a tie!")
            else:
                self.current_player = "O" if self.current_player == "X" else "X"
                self.label.configure(text=f"Player {self.current_player}'s turn")

    def check_winner(self):
        wins = [(0, 1, 2), (3, 4, 5), (6, 7, 8),
                (0, 3, 6), (1, 4, 7), (2, 5, 8),
                (0, 4, 8), (2, 4, 6)]
        for a, b, c in wins:
            if self.board[a] == self.board[b] == self.board[c] and self.board[a] is not None:
                return True
        return False

    def disable_buttons(self):
        for btn in self.buttons:
            btn.configure(state="disabled")

    def restart(self):
        self.board = [None] * 9
        self.current_player = "X"
        self.label.configure(text="Tic Tac Toe")
        for btn in self.buttons:
            btn.configure(text="", state="normal")

if __name__ == "__main__":
    app = TicTacToe()
    app.mainloop()
