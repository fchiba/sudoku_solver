#!/usr/bin/env ruby
require "set"
require "pp"

def dup_board(board)
    board.map{|row| row.dup }
end
def dup_candidates(candidates)
    candidates.map{|row| row.map{|candidate| candidate.dup} }
end

def print_board(board)
    puts board.map{ |row| row.map{|c| c ? c : " "}.join}.join("\n")
end

def print_candidates(candidates)
    27.times{ |j|
        y = j / 3
        num_y = j % 3
        27.times{ |i|
            x = i / 3
            num_x = i % 3
            num = num_y*3 + num_x + 1
            print candidates[y][x].include?(num) ? num : "*"
            print " " if num_x == 2
        }
        puts if num_y == 2
        puts
    }
end

board_original = open(ARGV[0]).read.split("\n").map{|line| line.split("").map{|c| c == " " ? nil : c.to_i }[0..9] }[0..9]
pp board_original


def narrow_candidate(x, y, board, candidate)
    if board[y][x]
        candidate.reject!{ |key| key != board[y][x] }
    end

    # scan x-axis
    9.times{ |xx|
        next if xx == x
        candidate.delete(board[y][xx]) if board[y][xx]
    }

    # scan y
    9.times{ |yy|
        next if yy == y
        candidate.delete(board[yy][x]) if board[yy][x]
    }

    # same region
    rx = (x/3)*3
    ry = (y/3)*3
    (ry...(ry+3)).each{ |yy|
        (rx...(rx+3)).each{ |xx|
            next if xx == x && yy == y
            candidate.delete(board[yy][xx]) if board[yy][xx]
        }
    }

end

def simple_solve(board, candidates)
    loop do
        9.times{ |y|
            9.times{ |x|
                narrow_candidate(x, y, board, candidates[y][x])
            }
        }
        changed = false
        9.times{ |y|
            9.times{ |x|
                if candidates[y][x].size == 1 && !board[y][x]
                    board[y][x] = candidates[y][x].first
                    changed = true
                end
            }
        }
        # 9.times{ |y|
        #     9.times{ |x|
        #         puts "#{x}, #{y}, #{board[y][x]}, #{candidates[y][x]}"
        #     }
        # }
        # sleep(1)
        break unless changed
    end
end

def solved?(candidates)
    min_candidates = 9
    max_candidates = 0
    9.times{ |y|
        9.times{ |x|
            min_candidates = [min_candidates, candidates[y][x].size].min
            max_candidates = [max_candidates, candidates[y][x].size].max
        }
    }

    if max_candidates == 1 && min_candidates == 1
        return :solved
    elsif min_candidates == 0
        return :inconsistent
    else
        return :unresolved
    end
end

def make_assumption(candidates, tested)
    sorted = candidates.flatten.each_with_index.filter{ |candidate, index| candidate.size > 1}.sort_by{ |candidate, index| candidate.size}
    sorted.each{ |candidate, index|
        x = index % 9
        y = index / 9
        candidate.each { |number|
            unless tested.include?([x,y,number])
                return [x,y,number]
            end
        }
    }
    exit "error!!!"
end

def solve_with_assumption(board_original)
    board = dup_board(board_original)
    candidates = Array.new(9) { Array.new(9) {Set.new(1..9)} }

    simple_solve(board, candidates)
    print_board(board)
    print_candidates(candidates)
    # STDIN.gets

    return board if solved?(candidates) == :solved
        

    tested = []
    loop do
        # print_board(board)

        (x,y,number) = make_assumption(candidates, tested)
        p [x,y,number]
        # STDIN.gets

        board_assumption = dup_board(board)
        board_assumption[y][x] = number
        candidates_assumption = dup_candidates(candidates)

        # print_board(board_assumption)
        # print_candidates(candidates_assumption)
        # STDIN.gets
        
        simple_solve(board_assumption, candidates_assumption)
        # print_candidates(candidates_assumption)
        # STDIN.gets

        case solved?(candidates_assumption)
        when :solved
            puts "solved"
            return board_assumption
        when :inconsistent
            puts "inconsistent with assumption #{number} at (#{y}, #{x})"
            # print_board(board_assumption)
            # print_candidates(candidates_assumption)
            # STDIN.gets

            candidates[y][x].delete(number)
            tested = []
            simple_solve(board, candidates)
            print_board(board)
            print_candidates(candidates)
            # STDIN.gets
        
        when :unresolved
            puts "unresolved"
            tested << [x,y,number]
            # do nothing
        end
    end
end

board = solve_with_assumption(board_original)
print_board(board)
