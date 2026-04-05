import subprocess
subprocess.check_call(["pip", "install", "pyinstaller"])

import tkinter as tk
import random

# Board size
GRID_SIZE = 10
CELL_SIZE = 60

# Snakes and Ladders configuration: start -> end
SNAKES = {16: 6, 47: 26, 49: 11, 56: 53, 62: 19, 64: 60, 87: 24, 93: 73, 95: 75, 98: 78}
LADDERS = {1: 38, 4: 14, 9: 31, 21: 42, 28: 84, 36: 44, 51: 67, 71: 91, 80: 100}


class SnakesLadders:
    def __init__(self, master):
        self.master = master
        self.master.title("Snakes and Ladders")

        self.canvas = tk.Canvas(master, width=GRID_SIZE * CELL_SIZE, height=GRID_SIZE * CELL_SIZE)
        self.canvas.pack()

        self.roll_button = tk.Button(master, text="Roll Dice", command=self.roll_dice)
        self.roll_button.pack(pady=10)

        self.status_label = tk.Label(master, text="Player 1's turn", font=("Arial", 14))
        self.status_label.pack()

        self.draw_board()

        self.player_positions = [0, 0]
        self.current_player = 0

        self.dice_roll = 0

        self.player_tokens = [
            self.canvas.create_oval(5, 5, 25, 25, fill='blue'),
            self.canvas.create_oval(35, 5, 55, 25, fill='orange')
        ]

        self.update_positions()

    def draw_board(self):
        # Draw the 10x10 grid
        color1, color2 = '#F0D9B5', '#B58863'  # Checkerboard colors
        for row in range(GRID_SIZE):
            for col in range(GRID_SIZE):
                x1 = col * CELL_SIZE
                y1 = (GRID_SIZE - 1 - row) * CELL_SIZE
                x2 = x1 + CELL_SIZE
                y2 = y1 + CELL_SIZE
                color = color1 if (row + col) % 2 == 0 else color2
                self.canvas.create_rectangle(x1, y1, x2, y2, fill=color)

                # Number the cells
                # Board numbering zig-zags left-right-right-left on alternating rows
                cell_num = row * GRID_SIZE + col + 1
                if row % 2 == 1:
                    cell_num = row * GRID_SIZE + (GRID_SIZE - col)

                self.canvas.create_text(x1 + CELL_SIZE/2, y1 + CELL_SIZE/2, text=str(cell_num), font=("Arial", 10))

        self.draw_snakes_and_ladders()

    def draw_snakes_and_ladders(self):
        # Convert a cell number to canvas x,y center
        def cell_center(cell):
            cell -= 1
            row = cell // GRID_SIZE
            col = cell % GRID_SIZE
            # Zigzag columns per row
            if row % 2 == 1:
                col = GRID_SIZE - 1 - col
            x = col * CELL_SIZE + CELL_SIZE / 2
            y = (GRID_SIZE - 1 - row) * CELL_SIZE + CELL_SIZE / 2
            return x, y

        # Draw snakes as red lines
        for start, end in SNAKES.items():
            x1, y1 = cell_center(start)
            x2, y2 = cell_center(end)
            self.canvas.create_line(x1, y1, x2, y2, fill='red', width=4, arrow=tk.LAST)

        # Draw ladders as green lines
        for start, end in LADDERS.items():
            x1, y1 = cell_center(start)
            x2, y2 = cell_center(end)
            self.canvas.create_line(x1, y1, x2, y2, fill='green', width=4, arrow=tk.LAST)

    def roll_dice(self):
        self.dice_roll = random.randint(1, 6)
        self.status_label.config(text=f"Player {self.current_player + 1} rolled a {self.dice_roll}")
        self.move_player()

    def move_player(self):
        pos = self.player_positions[self.current_player]
        new_pos = pos + self.dice_roll

        if new_pos > 100:
            new_pos = pos  # Do not move if beyond 100

        else:
            # Check for snakes or ladders
            if new_pos in SNAKES:
                new_pos = SNAKES[new_pos]
                self.status_label.config(text=f"Player {self.current_player + 1} got bitten by a snake! Moved down to {new_pos}.")
            elif new_pos in LADDERS:
                new_pos = LADDERS[new_pos]
                self.status_label.config(text=f"Player {self.current_player + 1} climbed a ladder! Moved up to {new_pos}.")

        self.player_positions[self.current_player] = new_pos
        self.update_positions()

        if new_pos == 100:
            self.status_label.config(text=f"Player {self.current_player + 1} wins!")
            self.roll_button.config(state=tk.DISABLED)

        else:
            # Switch player turn
            self.current_player = 1 - self.current_player
            self.status_label.config(text=f"Player {self.current_player + 1}'s turn")

    def update_positions(self):
        # Convert cell number to canvas x,y
        def cell_coords(cell, index):
            cell -= 1
            row = cell // GRID_SIZE
            col = cell % GRID_SIZE
            if row % 2 == 1:
                col = GRID_SIZE - 1 - col
            x = col * CELL_SIZE + 10 + (index * 25)
            y = (GRID_SIZE - 1 - row) * CELL_SIZE + 10
            return x, y

        for i, pos in enumerate(self.player_positions):
            if pos == 0:
                # Start position off board
                coords = (10 + i * 25, GRID_SIZE * CELL_SIZE + 10)
            else:
                coords = cell_coords(pos, i)
            self.canvas.coords(self.player_tokens[i], coords[0], coords[1], coords[0] + 20, coords[1] + 20)


def main():
    root = tk.Tk()
    game = SnakesLadders(root)
    root.mainloop()


if __name__ == '__main__':
    main()
