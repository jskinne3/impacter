require 'csv'

def delete_existing
  Answer.delete_all
  Question.delete_all
  Knock.delete_all
  Door.delete_all
  Canvasser.delete_all
end

def indexing_on
  Answer.__elasticsearch__.create_index!(force: true)
end

def create_questions
  # These are the text of questions as they appear in the spreadsheet "I. Salas_RESPONSES CIL Survey for non-VAN individuals"
  Question.create!(
    main_question_text: '1. Is there something you like about Lincoln, our community, and/or our neighborhood? (CIL POSITIVE)',
    notes_question_text: 'CIL Positive Open Notes: ',
    description: 'Positive'
  )
  Question.create!(
    main_question_text: '2. What is something you would like to improve, or what is one thing you’d like to change about Lincoln, our community, and/or our neighborhood? (CIL CONCERN)',
    notes_question_text: 'CIL Concern Open Notes: ',
    description: 'Concern'
  )
  Question.create!(
    main_question_text: nil,
    notes_question_text: '3. We’re trying to identify issues that impact people’s lives such as health care, jobs, housing, or anything else that comes to your mind. We’re curious to hear what in your life is an issue that is a challenge for you or those around you?',
    description: 'Issues'
  )
  Question.create!(
    main_question_text: '4. As we mentioned earlier, we want to hear about issues that impact your life, such as employment and jobs. How do you feel about your current job situation? How does employment impact your life, and those around you?',
    notes_question_text: '4a. Jobs: open notes section',
    description: 'Job'
  )
  Question.create!(
    main_question_text: '5. Another issue we’ve been hearing a lot about is transportation. What’s your experience with getting around in Lincoln?',
    notes_question_text: '5a. Transportation: open notes section',
    description: 'Transportation'
  )
  Question.create!(
    main_question_text: '6. Another issue we’ve been hearing about is housing. How do you feel about your housing situation or the housing situation in your neighborhood?',
    notes_question_text: '6a. Housing: open notes section',
    description: 'Housing'
  )
  Question.create!(
    main_question_text: '7. Have you talked to anyone about the issue that you mentioned earlier-- neighbors, friends, city officials, etc.?',
    notes_question_text: '7a: Who has this individual talked to?',
    description: 'Contact'
  )
  Question.create!(
    main_question_text: '8. Do you think it would be useful if you contacted the [insert appropriate power structure here] about this issue?',
    notes_question_text: '8A: (above answer was no) What is discouraging you or preventing you from contacting the city/state about this issue? What are those barriers?',
    description: 'Discouraged'
  )
  Question.create!(
    main_question_text: '9. How do you feel places like schools, the city, or churches etc are doing to address your needs? ',
    notes_question_text: 'CIL Confidence in Institutions Open Notes:',
    description: 'Institutions'
  )
  Question.create!(
    main_question_text: '10. Are there any communities that you are connected to, either in or outside of your neighborhood? What do you do in your spare time?  Examples: schools, church groups, recreational activities, cultural centers, neighborhood associations.',
    notes_question_text: 'CIL Community Member Open Notes:',
    description: 'Communities'
  )
  Question.create!(
    main_question_text: '11.  Are you comfortable having a conversation with newcomers in your neighborhood?',
    notes_question_text: nil,
    description: 'Newcomers'
  )
  Question.create!(
    main_question_text: '12. Would you be interested in learning more about a Community Builder Workshop?',
    notes_question_text: nil,
    description: 'Workshop'
  )
  Question.create!(
    main_question_text: '13. Would you be interested in volunteering for neighborhood-specific events (e.g. block party, potluck)? (NVOL)',
    notes_question_text: nil,
    description: 'Volunteering'
  )
  Question.create!(
    main_question_text: 'Internal question: is there any follow up needed with this individual? What issue is it surrounding?',
    notes_question_text: 'Other Notes:',
    description: 'Notes'
  )
end

def upload_non_van
  non_van_file = 'data/IsabelNonVAN.csv'
  csv_text = File.read(non_van_file)
  csv = CSV.parse(csv_text, :headers => true)
  csv.each do |row|
    row.each{|k, v| row[k.strip] = v}
    door = Door.find_or_create_by(
      address: row['Street Address:'],
      zip: row['Zip Code']
    )
    canvasser = Canvasser.find_or_create_by(
      name: row['Canvassed by:'].strip
    )
    knock = Knock.create!(
      door: door,
      canvasser: canvasser,
      when: row['Timestamp'],
      resident_name: "#{row['First Name:'].to_s.strip} #{row['Last Name:'].to_s.strip}".strip,
      neighborhood: row['Neighborhood:'].strip,
      language: row['What is your preferred language?'],
      race: row['How would you describe your race/ethnicity?'],
      gender: row['What is your self identified gender?'],
    )
    # Get the answers to each of the survey questions created above and save to the knock
    for question in Question.all
      main = row[question.main_question_text]
      note = row[question.notes_question_text]
      knock.answers.create!(
        short_answer: main,
        notes: note,
        question: question
      )
    end
    puts "#{knock.id} #{knock.gender} #{knock.canvasser_id} #{knock.door_id} A: #{knock.answers.count}" if knock.persisted?
  end
end # end of def upload_non_van


def upload_van
#  van_file_numeric = 'data/CILsurveyresponses20190115-2424875393.csv'
#  csv_text_numeric = File.read(van_file_numeric)
#  csv = CSV.parse(csv_text_numeric, {headers: true, col_sep: "\t"})
#  csv.each do |row|
#    puts "*** #{row['Voter File VANID']}"
#  end

  van_file_numeric = 'data/export1668637-2369214289.csv'
  csv_text_numeric = File.read(van_file_numeric)
  csv = CSV.parse(csv_text_numeric, {headers: true, col_sep: "\t"})
  csv.each do |row|
    puts "*** #{row['Voter File VANID']} #{row['ContactName']} #{row['NoteText'].to_s[0..20]}"
  end
  puts " end answer data ..."
end

# Run the above-defined functions
delete_existing
indexing_on
create_questions
upload_non_van
#upload_van




