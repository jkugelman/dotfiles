#!/usr/bin/env python

import string, sys, time

verbose = "-q" not in sys.argv

def main():
    print "Forward:"
    raft.find_fit(pieces, delay=0.002)
    print
    print "Backward:"
    raft.find_fit([piece.flipped() for piece in pieces], delay=0.002)

class Piece(list):
    def __init__(self, sides):
        self[:] = sides

    def flipped(self):
        return Piece(self[3:6] + self[0:3])

    def fits_below(self, other): return other is None or self[0] != other[3]
    def fits_above(self, other): return other is None or other.fits_below(self)
    def fits_left (self, other): return other is None or self[1] != other[5] and self[2] != other[4]
    def fits_right(self, other): return other is None or other.fits_left(self)

    def fits_in(self, raft, row, col):
        return self.fits_below(raft[row - 1][col]) \
           and self.fits_above(raft[row + 1][col]) \
           and self.fits_right(raft[row][col - 1]) \
           and self.fits_left (raft[row][col + 1])

class Raft(list):
    def __init__(self, pieces):
        self[:] = [row[:] for row in pieces]

    def find_fit(self, pieces, delay, solution=[]):
        for row in range(len(self)):
            for col in range(len(self[row])):
                if self[row][col] is not None:
                    continue

                for i in range(len(pieces)):
                    if pieces[i] is None:
                        continue

                    piece  = pieces[i]
                    letter = string.uppercase[i]

                    if verbose:
                        sys.stdout.write(letter)
                        sys.stdout.flush()

                    if piece.fits_in(self, row, col):
                        solution.append(letter)
                        self[row][col] = piece
                        pieces[i]      = None

                        if all(x is None for x in pieces):
                            if verbose:
                                sys.stdout.write("\r            \r")

                            self.show_solution(solution)
                        else:
                            self.find_fit(pieces, delay, solution)

                        pieces[i]      = piece
                        self[row][col] = None
                        solution.pop()

                    if verbose:
                        time.sleep(delay)
                        sys.stdout.write("\b \b")
                        sys.stdout.flush()

                # Nothing fits in empty square.
                return

    def show_solution(self, solution):
        sys.stdout.write(".--&--.\n")

        for i in range(len(solution) / 3):
            sys.stdout.write("(%s)\n" % (" ".join(solution[i * 3 : i * 3 + 3])))

        sys.stdout.write("'-----'\n")

raft = Raft([
    [Piece("------"), Piece("---i--"), Piece("---i--"), Piece("---i--"), Piece("------")],
    [Piece("-io---"), None,            None,            None,            Piece("----oi")],
    [Piece("-io---"), None,            None,            None,            Piece("----io")],
    [Piece("-io---"), None,            None,            None,            Piece("----io")],
    [Piece("-oi---"), None,            None,            None,            Piece("----io")],
    [Piece("------"), Piece("o-----"), Piece("o-----"), Piece("o-----"), Piece("------")],
])
    
pieces = [
    Piece("ioiooi"),
    Piece("iiooio"),
    Piece("oioiio"),
    Piece("ioiioi"),
    Piece("ooiooi"),
    Piece("iioioi"),
    Piece("ooiioi"),
    Piece("iioooi"),
    Piece("ooioio"),
    Piece("oioooi"),
    Piece("ooiiio"),
    Piece("ioiiio"),
]

if __name__ == "__main__":
    main()
