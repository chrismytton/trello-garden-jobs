# Trello garden jobs

A GitHub Actions workflow runs `bin/make_trello_card` once a day. This script uses the data from [chrismytton/gardeners-world-monthly-jobs](https://github.com/chrismytton/gardeners-world-monthly-jobs) and generates a monthly card for garden jobs that need doing. It will only generate the card for the current month if there isn't already one on the target board.
