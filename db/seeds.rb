require 'csv'
require 'pp'

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
      unless main.blank? && note.blank?
        knock.answers.create!(
          short_answer: main,
          notes: note,
          question: question
        )
      end
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
      # Weird because I'm re-saving the date once per note.
      # A few doors were surveyed twice in different years, so, this can end up wrong.
      # Also, it means that knocks without notes get no date !!
      knock.when = Date.strptime(row['DateEntered'], "%m/%d/%Y")
      knock.save
    end
  end
end

def add_vanids(name, vanids)
  puts "adding #{vanids.length} VANids, #{vanids.uniq.length} unique, for #{name}"
  canvasser = Canvasser.where(name: name).first
  if canvasser
    for vanid in vanids
      k = Knock.where(vanid: vanid).first
      if k
        k.canvasser = canvasser
        puts "saved #{k.resident_name}" if k.save
      else
        puts "###### No knock of that VANid"
      end
    end
  else
    puts "Canvasser record not found"
  end
end

def update_dates
  missing_dates = {
  1141980 => '10/4/17',
  2225064 => '10/17/17',
  1466612 => '10/3/17',
  1306768 => '5/24/18',
  686808  => '10/26/17',
  793300  => '9/27/18',
  #1306364 => '', # no survey responses...
  789563  => '9/12/18',
  805581  => '10/18/17',
  2096796 => '10/11/17',
  1629677 => '10/17/18',
  771089  => '10/9/17',
  2027751 => '8/27/18',
  684063  => '9/26/17',
  1197925 => '10/17/18',
  2032574 => '4/23/18',
  #829131  => '', # no responses
  #772501  => '', # no responses
  987601  => '10/30/17',
  848929  => '9/12/18',
  1449359 => '9/12/18',
  1916555 => '9/26/17',
  776780  => '8/27/18',
  #720574  => '', # none
  1686724 => '9/12/18',
  1249703 => '10/26/17',
  1556200 => '9/12/18',
  1597160 => '10/16/17',
  700357  => '9/12/18',
  2053144 => '8/15/18',
  1937114 => '11/19/17',
  #786861  => '', # none
  828960  => '11/2/17',
  743756  => '10/26/17',
  709335  => '10/4/17',
  685127  => '11/14/18',
  694556  => '5/22/18',
  763780  => '9/12/18',
  2001282 => '10/17/18',
  1307142 => '11/27/17',
  1355167 => '9/12/18',
  762838  => '10/4/17',
  2074743 => '10/13/17',
  755755  => '4/20/18',
  774455  => '4/27/18',
  772140  => '10/3/17',
  803505  => '9/11/18',
  729079  => '9/19/18',
  695233  => '9/12/18',
  750927  => '4/28/18',
  1900298 => '10/23/17',
  2004645 => '5/14/18',
  840763  => '10/2/17',
  1697477 => '4/23/18',
  1827975 => '10/3/17',
  718528  => '9/27/18',
  2252545 => '9/12/18',
  2170880 => '11/1/18',
  712165  => '10/3/18',
  739952  => '10/17/17',
  837547  => '10/3/17',
  772173  => '11/19/17',
  712213  => '4/23/18',
  790223  => '4/28/18',
  2065899 => '10/26/17',
  813605  => '11/28/18'
  }
  
  missing_dates.each do |k, v|
    date = Date.strptime(v, "%m/%d/%y")
    knock = Knock.where(vanid: k).first
    knock.when = date
    if knock.save
      puts "#{k} #{v}"
    else
      puts "=========== didn't save ==========="
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
#delete_existing
#indexing_on
#create_questions
#upload_non_van
#upload_van_numeric
#upload_van_notes
update_dates
#add_vanis('Jewel', [1596319, 693282, 696961, 1542288, 699594, 705839, 46732, 717014, 1666135, 1298865, 727648, 1363592, 2192397, 744246, 750256, 750257, 751313, 755754, 760980, 774468, 775607, 2027980, 1039046, 2107253, 785780, 795049, 794311, 803349, 805198, 823808, 846383, 826816, 828404, 1743814, 834049, 842023, 849577])

#add_vanids('José Lemus', [
#705927, 260793, 684230, 685536, 1817783, 687450, 687521, 689128, 690567, 691285, 693021, 693022, 2096540, 2096541, 694556, 2192078, 2134091, 1810163, 700989, 2168587, 705168, 707355, 707468, 736890, 710561, 2053144, 714668, 717741, 1543102, 724001, 1559233, 737115, 744544, 2182854, 1598175, 746236, 746727, 748914, 749888,
#2182854, 1598175, 746236, 746236, 748914, 749888, 752592, 755889, 755890, 756911, 923193, 762835, 762838, 763058, 763633, 766398, 1469596, 1296793, 1239257, 768405, 1734436, 1598811, 1448551, 1790374, 987601, 778587, 783898, 784438, 785240, 2170135, 1704604, 2147254, 1546475, 791744, 796661, 797346, 2065115, 2082191, 798811,
#804702, 805031, 805318, 805504, 805959, 805963, 806329, 807836, 562815, 989381, 811594, 811756, 811785, 1905162, 1547391, 1547404, 814580, 815034, 817202, 1835834, 820942, 823179, 824560, 2226938, 830062, 837969, 838022, 838728, 2095281, 841450, 1548620, 2039822, 843190, 843622, 845137, 1726199, 846446, 848070, 2075303, 849264
#])

#add_vanids('Selina Martinez', [
#1859668, 139983, 708191, 709098, 709107, 2210942, 720574, 712213, 846728, 728778, 731678, 739081, 743442, 745269, 746446, 2071061, 748795, 1544524, 750904, 755755, 763776, 770146, 770985, 2007567, 772501, 774455, 775036, 777768, 779574, 1328622, 2073799, 773704, 786861, 789866, 791131, 792756, 794033, 796914, 798631,
#2041818, 813601, 813605, 2252378, 990255, 829131, 834504, 531883, 125009, 1697477, 842221, 843949
#])

#add_vanids('Damali and Natasha', [
#694166, 712165, 718528, 721646, 770236, 776780, 1297335
#])

#add_vanids('Damali Britton', [
#809448, 695233, 1686724, 700357, 720516, 1449359, 841746, 763780, 770933, 1556200, 793300, 789563, 803505, 817952, 2252545, 837576, 848929
#])

# VANids I've encountered that are in VAN as knocked but aren't in db
# 1297335 776780
