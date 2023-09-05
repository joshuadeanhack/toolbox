
# Plan

# version one is notes only 
# version two is note times and playback??

# Static data to store the scales
# Static data to store the mode flat modifier

# data to store the final scale you are using (apply mode to scale)
# data to store the original theme - as solfa (with a way of multiple octaves (going outside a single octave))

# temporary final theme data (solfa turned into notes)

# Add note to theme function -> add a solfa note to the theme sequence

# create modal_scale -> notes
# a transposer function - takes the theme and a modal scale -> notes "Get theme function"

###

# import scales and modes as json

# dataclass NoteSequence - holds a dictionary of notes with octave number as a string/enum

# var ModalScale[NoteSeq] - hold the current scale that you're using. It would hold a reference to a Scale and a Mode instance, and could have a method to apply the mode to the key.
# var Theme[NoteSeq] - hold your solfa-based theme - appending a number to each note (e.g., 'do1', 're1', 'mi2' for do-re-mi where mi is an octave higher)

# functions - Transpose(themeseq, modalscale) -> noteseq 
#           - CreateModalScale(scale, mode) -> noteseq
#           - 

from dataclasses import dataclass
from collections import deque

@dataclass 
class Note():
    value: str = None
    octave: int = 1

class NoteSequence():
    notes = deque() 

    # Add a note to the end of the seqeunce
    def add(self, note: Note) -> None:
        self.notes.append(note)

    # Remove a note at a given index
    def remove(self, index: int) -> None:
        if 0 <= index < len(self.notes):
            self.notes.remove(index)

    # Remove the last note
    def pop(self) -> None:
        self.notes.pop()

    # Reverse the note sequence
    def reverse(self) -> None:
        self.notes.reverse()

    # Rotate the note sequence by a given transformation number
    def rotate(self, transform: int) -> None:
        self.notes.rotate(transform)

    # Print the notes
    def print(self) -> None:
        print("Notes: ", end="")
        for note in self.notes:
            print(f"{note.value}-{note.octave}", end=" ")
        print()


# Test code

notes = NoteSequence()

newNote = Note(value="mi")
notes.add(newNote)
notes.print()

for i in range(2):
    notes.add(Note(value="re"))
notes.print()
notes.rotate(-2)
notes.print()


# Modify notes of a scale based on the mode modifier
def CreateModalScale(scale: dict, mode: dict) -> dict:
    # Loop through each value in the scale and mode at the same time
    for (k1, v1), (k2, v2) in zip(scale.items(), mode.items()):
        print(f"Scale {k1}: {v1} Mode {k2}: {v2}")
    
    # Add condition and function call here that modifies the note semi-tone based on v2

    # Return the new modalscale as dict - { solfa: absolute_note }

# Function to change an absolute note based on number of semi-tones changed

# Static data Note Order...

# Function to load a note sequence and a modalscale dict - generates a new NoteSeq 
# Loop -> new_note.value = modalscale[solfa_note.value] 