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
    description: 'Positive',
    van_code: 'CILPOS',
    van_name: 'CIL_Positive'
  )
  Question.create!(
    main_question_text: '2. What is something you would like to improve, or what is one thing you’d like to change about Lincoln, our community, and/or our neighborhood? (CIL CONCERN)',
    notes_question_text: 'CIL Concern Open Notes: ',
    description: 'Concern',
    van_code: 'CILCON',
    van_name: 'CIL_Concerns'
  )
  Question.create!(
    main_question_text: nil,
    notes_question_text: '3. We’re trying to identify issues that impact people’s lives such as health care, jobs, housing, or anything else that comes to your mind. We’re curious to hear what in your life is an issue that is a challenge for you or those around you?',
    description: 'Issues',
    van_code: 'CILOEI',
    van_name: 'CIL_Open_Issue'
  )
  Question.create!(
    main_question_text: '4. As we mentioned earlier, we want to hear about issues that impact your life, such as employment and jobs. How do you feel about your current job situation? How does employment impact your life, and those around you?',
    notes_question_text: '4a. Jobs: open notes section',
    description: 'Job',
    van_code: 'CILJOB',
    van_name: 'CIL_Jobs'
  )
  Question.create!(
    main_question_text: '5. Another issue we’ve been hearing a lot about is transportation. What’s your experience with getting around in Lincoln?',
    notes_question_text: '5a. Transportation: open notes section',
    description: 'Transportation',
    van_code: 'CILTPT',
    van_name: 'CIL_Transportation'
  )
  Question.create!(
    main_question_text: '6. Another issue we’ve been hearing about is housing. How do you feel about your housing situation or the housing situation in your neighborhood?',
    notes_question_text: '6a. Housing: open notes section',
    description: 'Housing',
    van_code: 'CILHSN',
    van_name: 'CIL_Housing'
  )
  Question.create!(
    main_question_text: '7. Have you talked to anyone about the issue that you mentioned earlier-- neighbors, friends, city officials, etc.?',
    notes_question_text: '7a: Who has this individual talked to?',
    description: 'Contact',
    van_name: 'CIL_Address_Issue_2'
  )
  Question.create!(
    main_question_text: '8. Do you think it would be useful if you contacted the [insert appropriate power structure here] about this issue?',
    notes_question_text: '8A: (above answer was no) What is discouraging you or preventing you from contacting the city/state about this issue? What are those barriers?',
    description: 'Discouraged',
    van_code: 'CILCPS',
    van_name: 'CIL_Contact_Power'
  )
  Question.create!(
    main_question_text: '9. How do you feel places like schools, the city, or churches etc are doing to address your needs? ',
    notes_question_text: 'CIL Confidence in Institutions Open Notes:',
    description: 'Institutions',
    van_code: 'CILCII',
    van_name: 'CIL_Conf_in_Institut'
  )
  Question.create!(
    main_question_text: '10. Are there any communities that you are connected to, either in or outside of your neighborhood? What do you do in your spare time?  Examples: schools, church groups, recreational activities, cultural centers, neighborhood associations.',
    notes_question_text: 'CIL Community Member Open Notes:',
    description: 'Communities',
    van_code: 'CILCM',
    van_name: 'CIL_Community_Member'
  )
  Question.create!(
    main_question_text: '11.  Are you comfortable having a conversation with newcomers in your neighborhood?',
    notes_question_text: nil,
    description: 'Newcomers',
    van_name: 'CIL_Connectedness'
  )
  Question.create!(
    main_question_text: '12. Would you be interested in learning more about a Community Builder Workshop?',
    notes_question_text: nil,
    description: 'Workshop',
    van_name: 'CIL_Com_Build_Wrkshp'
  )
  Question.create!(
    main_question_text: '13. Would you be interested in volunteering for neighborhood-specific events (e.g. block party, potluck)? (NVOL)',
    notes_question_text: nil,
    description: 'Volunteering',
    van_name: 'CIL_Neighborhood_VOL'
  )
  Question.create!(
    main_question_text: 'Internal question: is there any follow up needed with this individual? What issue is it surrounding?',
    notes_question_text: 'Other Notes:',
    description: 'Notes',
  )
end

def upload_non_van
  non_van_file = 'data/IsabelNonVAN.csv'
  csv_text = File.read(non_van_file)
  csv = CSV.parse(csv_text, :headers => true)
  csv.each do |row|
    puts "*** upload_non_van"
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
      when: row['Timestamp'].blank? ? nil : Date.strptime(row['Timestamp'], "%m/%d/%Y"),
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
  end
end # end of def upload_non_van


def upload_van_numeric
  # VAN data is in two .csv files; one with numeric 1-5 responses, and one with free-form notes.
  # I want to create records for each numeric response, and associate the notes when they exist.
  # upload_van_numeric must be run *before* upload_van_notes is run

  # Isabel is the only Canvasser in VAN for whom I have identifying info, a list of VAN ids
  isabel = Canvasser.where(name: 'Isabel').first
  unknown_canvasser = Canvasser.create!(name: 'Unknown')
  isabel_vanids = [32000, 749102, 807063, 771313, 1190562, 1278119, 1362550, 1674919, 1897895, 1936223, 2074571, 2206981, 757155, 774903, 2074145, 811563, 988959, 1363549, 716301, 2134418, 1663766, 2135755, 2148656, 831426, 697915, 1533142, 1539435]

  van_file_numeric = 'data/CILsurveyresponses20190115-2424875393.csv'
  csv_text_numeric = File.read(van_file_numeric)
  csv_text_numeric.delete!("\u0000") # Avoid error "string contains null byte"
  csv = CSV.parse(csv_text_numeric, {headers: true, col_sep: "\t"})
  csv.each do |row|
    puts "*** upload_van_numeric"
    door = Door.find_or_create_by(
      address: row['Address'],
      zip: row['Zip5']
    )
    knock = Knock.create!(
      door: door,
      canvasser: isabel_vanids.include?(row['Voter File VANID'].to_i) ? isabel : unknown_canvasser,
      #when: row['Timestamp'],
      resident_name: "#{row['FirstName'].to_s.strip} #{row['LastName'].to_s.strip}".strip,
      #neighborhood: row['Neighborhood:'].strip,
      language: row['What is your preferred language?'],
      #race: row['How would you describe your race/ethnicity?'],
      gender: row['Sex'],
      email: row['PreferredEmail'],
      phone: row['Preferred Phone'],
      vanid: row['Voter File VANID'],
      dwid: row['DWID']
    )
    # Create answers for each question asked during this knock
    for question in Question.all
      data = row[question.van_name]
      if data
        unless data.blank?
          knock.answers.create!(
            short_answer: data,
            question: question
          )
        end
      end
    end
  end
end

def upload_van_notes
  codes = Question.all.map{|q| q.van_code}.uniq
  van_file_numeric = 'data/export1668637-2369214289.csv'
  csv_text_numeric = File.read(van_file_numeric)
  csv = CSV.parse(csv_text_numeric, {headers: true, col_sep: "\t"})
  csv.each do |row|
    puts "*** upload_van_notes"
    # Going to add whatever notes are discovered to the answer given for this knock
    knock = Knock.where(vanid: row['Voter File VANID']).first
    # If the data is broken up with codes, associate it with the correct question
    notes_text = row['NoteText'].to_s.gsub('ﾒ',"'") # remove erroneous character
    notes_text_as_array = notes_text.gsub(':','').split # remove colons to clean codes
    # If notes begin with a code, guess that they should be divided by code
    if codes.include? notes_text_as_array[0].upcase
      notes_array_sliced = notes_text_as_array.slice_before { |word| codes.include?(word.upcase) }
      notes_hash = notes_array_sliced.map { |word, *rest| [word, rest.join(' ')] }.to_h
      # Save each note in the hash under the correct question
      notes_hash.each do |code, text|
        unless text.blank?
          question = Question.where(van_code: code).first
          answer = knock.answers.find_or_create_by(question: question)
          answer.notes = "#{code}: #{text}"
          answer.save
        end
      end
    else
      unless notes_text.blank?
        # Otherwise, wave the whole notes text under Other Notes question
        question = Question.where(description: 'Notes').first
        answer = knock.answers.find_or_create_by(question: question)
        # Append rather than overwrite, because there could be more than one
        if answer
          (answer.notes = '') if answer.notes.nil?
          answer.notes << notes_text
          answer.save
        end
      end
    end
    unless row['DateEntered'].blank?
      knock.when = Date.strptime(row['DateEntered'], "%m/%d/%Y")
      knock.save
    end
  end
end

# Stuff to add to VAN data export as of 13 Feb 2019:
# Canvasser: Notes List -> Customize Export -> Include Canvasser Status
# precincts
# Preferred Language
# Race/Ethnicity
# Gender Identity
# CIL Up to Date

# Run the above-defined functions
delete_existing
indexing_on
create_questions
upload_non_van
upload_van_numeric
upload_van_notes




