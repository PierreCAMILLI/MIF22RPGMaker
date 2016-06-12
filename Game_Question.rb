#==============================================================================
# ** Game_Questions
#------------------------------------------------------------------------------
#  Cette classe gère la lecture, l'affichage et l'intéraction avec les questions.
#------------------------------------------------------------------------------
# * Fonctions à utiliser :
# * - display_questions_list : Affiche la liste des questions
# * - ask_question(q) : Pose la question numéro q ou portant l'identifiant q
# *                     Renvoie true/false selon si la réponse donnée est juste ou fausse
# * - ask_random_question : Pose une question aléatoirement parmi la liste des questions
# * - ask_every_questions : Pose toutes les questions de la liste des question
# *                         Retourne un tableau de true/false correspondant aux réponses données
#==============================================================================
class Game_Interpreter
  
  #--------------------------------------------------------------------------
  # * Object Initialization
  #--------------------------------------------------------------------------
  attr_reader   :data # Tableau contenant le fichier JSON lu
  attr_reader   :dataLesson # Tableau contenant le fichier JSON de cours
  attr_reader   :results # Resultat des questions
  @@questionFailed = Array.new # Liste des questions trop ratées qui seront reposée par un boss

  
  #--------------------------------------------------------------------------
  # * Affiche la liste des questions dans une boîte de dialogue
  #--------------------------------------------------------------------------
  def display_questions_list
    #read_json
    $game_message.add("Voici la liste des questions :")
    for i in 0..((get_data["questions"].count)-1)
      show_message_fitting_box(get_data["questions"][i]["question"])
    end
  end
  
  #--------------------------------------------------------------------------
  # * Pose la quest-ème question de la liste et retourne vrai si la réponse donnée est juste
  #--------------------------------------------------------------------------
  def ask_question(quest = -1)
    if (quest.is_a?(String))
      return ask_question_by_id(quest)
    end
    #read_json
    if quest < (get_data["questions"].count) or quest > 0
      # Affichage de la question
      show_message_fitting_box(get_data["questions"][quest]["question"])
      # Gestion du choix
      res = show_choice(get_data["questions"][quest]["choix"])
      update_results(get_data["questions"][quest]["id"], res)  # On met à jour notre Hash de résultats
      return res
    end
    return false
  end
  
  #--------------------------------------------------------------------------
  # * Pose une question aléatoire parmi la liste des questions
  #--------------------------------------------------------------------------
  def ask_random_question
    #read_json
    ask_question(Random.rand(get_data["questions"].count+1)-1)
  end
  
  #--------------------------------------------------------------------------
  # * Pose toutes les questions de la liste arr
  #--------------------------------------------------------------------------
  def ask_several_questions(arr)
    #read_json
    answers = []
    arr.each_with_index do |v,i|
      answers.push(ask_question(i))
    end
    return answers
  end
  
  #--------------------------------------------------------------------------
  # * Pose toutes les questions de la liste des questions
  #--------------------------------------------------------------------------
  def ask_every_questions
    #read_json
    answers = []
    (get_data["questions"]).each_with_index do |v,i|
      answers.push(ask_question(i))
    end
    return answers
  end
  
  #--------------------------------------------------------------------------
  # * Pose la question dont l'id correspond à celui passé en paramètre
  #--------------------------------------------------------------------------
  def ask_question_by_id(quest = "")
    #read_json
    get_data["questions"].each_with_index do |q,i|
      if(q.has_key? 'id' and (q["id"]).eql? quest)
        return ask_question(i)
      end
    end
    return false
  end
  
  #--------------------------------------------------------------------------
  # * Découpe la chaîne de caractère passé en paramètre pour rentrer dans le message box
  #--------------------------------------------------------------------------
  def split_string(str)
    # On sépare la ligne de texte en mots
    str_arr = str.split(' ')
    # Initialisation
    line_arr = []
    new_str = ''
    # Parcours des mots
    str_arr.each do |s|
      # Si un mot est trop long
      if s.size > 50
        new_str = s
      # Si un mot fait dépasser la taille d'un ligne
      elsif new_str.size + s.size > 50
        line_arr.push(new_str)
        new_str = s
      # On ajoute un mot à la ligne
      elsif new_str.size != 0
        new_str = new_str + ' ' + s
      else
        new_str = s
      end
    end
    line_arr.push(new_str)
    return line_arr
  end
  
  #--------------------------------------------------------------------------
  # * Affiche le message passé en paramètre rentrant dans le message box
  #--------------------------------------------------------------------------
  def show_message_fitting_box(str)
    lines = split_string(str)
    lines.each do |l|
      $game_message.add(l)
    end
  end
  
  #--------------------------------------------------------------------------
  # * Propose les choix passés en paramètre, renvoi true/false selon si le choix
  # * exécuté correspond à ans
  #--------------------------------------------------------------------------
  def show_choice(ch)
    # On répertorie les différents indexs des réponses dans un tableau (sauf le premier)
    ch_ind = []
    for i in 1..(ch.size - 1)
      ch_ind.push(i)
    end
    # On mélange le tableau
    shuf = ch_ind.shuffle
    # On réduit le tableau jusqu'à ce qu'il soit de taille 3
    while shuf.size > 3
      shuf.pop
    end
    # On ajoute la première réponse (la bonne)
    shuf.push(0)
    
    # On mélange à nouveau le tableau
    shuffled = shuf.shuffle
    # On insère les réponses mélangées dans un tableau
    ch_to_push = []
    shuffled.each do |i|
      ch_to_push.push(ch[i])
    end
    
    # On insère les choix dans la boite de choix et on paramètre la boite
    params = []
    params.push(ch_to_push)       # On insère les réponses dans la boite de choix
    params.push(0)        # On ne peut pas s'échapper du choix en faisant Echap
    setup_choices(params) # On affiche les choix
    wait_for_message      # On attend que le joueur ait fait son choix
    # On retourne la réponse donnée
    return shuffled[@branch[@indent]] == 0  # Si le choix rentré est le bon, on retourne true
  end
  
  #--------------------------------------------------------------------------
  # * Lit le fichier JSON pour parser son contenu dans la variable @data
  #--------------------------------------------------------------------------
  def read_json
    json = ""
    File.open("Json/questions.json").each do |line|
      json += line
    end
    @data = JSON.decode(json)
  end
  
  #--------------------------- Partie Cours ---------------------------------
  
  #--------------------------------------------------------------------------
  # * Lit le fichier JSON pour parser son contenu dans la variable @dataLesson
  #--------------------------------------------------------------------------
  def read_json_lesson
    json = ""
    File.open("Json/cours.json").each do |line|
      json += line
    end
    @dataLesson = JSON.decode(json)
  end
  
  #--------------------------------------------------------------------------
  # * Lit le cours dont l'id correspond à celui passé en paramètre
  #--------------------------------------------------------------------------
  def read_lesson_by_id(quest = "")
    #read_json
    get_data_lesson["cours"].each_with_index do |q,i|
      if(q.has_key? 'id' and (q["id"]).eql? quest)
        return read_lesson(i)
      end
    end
    return false
  end
  
  #--------------------------------------------------------------------------
  # * Lit la ieme lecon de la liste, renvoie true si la lecon existe, false sinon
  #--------------------------------------------------------------------------
  def read_lesson(quest = -1)
    show_message_fitting_box(get_data_lesson["cours"][quest]["texte"])
    #if quest < (get_data_lesson["cours"].count) or quest > 0
      # Affichage de la lecon
      #show_message_fitting_box(get_data_lesson["cours"][quest]["texte"])
      #return true
    #end
    return true
  end
  
  #--------------------------------------------------------------------------
  
  #--------------------------------------------------------------------------
  # * Retourne le contenu parsé du fichier JSON
  # * Si la variable est vide, on parse le fichier
  #--------------------------------------------------------------------------
  def get_data
    if(@data.nil?)
      read_json
    end
    return @data
  end
  
  #--------------------------------------------------------------------------
  # * Retourne le contenu parsé du fichier JSON cours
  # * Si la variable est vide, on parse le fichier
  #--------------------------------------------------------------------------
  def get_data_lesson
    if(@dataLesson.nil?)
      read_json_lesson
    end
    return @dataLesson
  end

  #--------------------------------------------------------------------------
  # * Retourne la Hash correspondant aux résultats
  #--------------------------------------------------------------------------
  def get_results
    return $game_system.results
  end
  
  #--------------------------------------------------------------------------
  # * Met à jour le tableau de réponses selon la réponse donnée
  #--------------------------------------------------------------------------
  def update_results(id, r)
    # On vérifie si l'index existe dans la Hash pour savoir si il faut créer un tableau
    if(!get_results.has_key?(id))
      get_results[id] = Array.new([0,0])
    end
    get_results[id][0] += 1
    if(!r)
      get_results[id][1] += 1
    end
  end
  
  #--------------------------------------------------------------------------
  # * Pose une question en fonction de celles qui on été le plus ratées
  #--------------------------------------------------------------------------
  def ask_failed_question()
    fill_QuestionFailedArray()
    ask_question(@@questionFailed.shift())
  end
  
  #--------------------------------------------------------------------------
  # * Remplie la liste de question à poser
  #--------------------------------------------------------------------------
  def fill_QuestionFailedArray()
    idQuestion = 0
    maxRate = 0.0
    for i in get_results()
      nombreTest = get_asked_questions(i[0]).to_i
      if(nombreTest == 0)
        nombreTest = nombreTest + 1
      end
      tmpRate = get_false_answers(i[0]).to_f / nombreTest.to_f
      if(tmpRate > maxRate)
        maxRate = tmpRate
        idQuestion = i[0]
      end
    end
    update_results(idQuestion, true)
    @@questionFailed.push(idQuestion)
  end
  
  #--------------------------------------------------------------------------
  # * Indique le nombre de fois que la question id a été posée
  #--------------------------------------------------------------------------
  def get_asked_questions(id)
    if(!get_results.has_key?(id))
      return ""
    end
    return get_results[id][0].to_s
  end
  
  #--------------------------------------------------------------------------
  # * Indique le nombre de mauvaise réponses données pour la question id
  #--------------------------------------------------------------------------
  def get_false_answers(id)
    if(!get_results.has_key?(id))
      return ""
    end
    return get_results[id][1].to_s
  end

  def statistiques()
    countQVues = 0
    rateRep = 0
    for i in get_results()
      countQVues += 1
      if(i[1][1].to_i > 0)
        rateRep += 1
      end
    end
    stat = "{\n"
    stat += "\"general\": "
    stat += "{"
    stat += "\"nom\": \"mickael\", "
    stat += "\"repTotales\": " + countQVues.to_s + ", "
    stat += "\"rateRep\": " + rateRep.to_s
    stat += "},\n"
    stat += "\"detail\": "
    stat += "["
    cpt = 0
    for i in get_results()
      stat += "{"
      stat += "\"id\": \"" + i[0].to_s + "\", "
      stat += "\"tentative\": " + i[1][0].to_s + ", "
      stat += "\"rate\": " + i[1][1].to_s
      if(cpt >= get_results().length - 1)
        stat += "}"
      else
        stat += "},"
      end
      cpt += 1
    end
    stat.to_s.chop
    stat += "]\n"
    stat += "}"
    File.open("Stats/stats.json", 'w') { |file| file.write(stat) }
  end
end

class Game_System
  
  attr_accessor   :results # Resultat des questions
  alias original_call initialize
  def initialize
    original_call()
    @results = Hash.new
  end
  
end

module DataManager
  
  def self.statistiques
    countQVues = 0
    rateRep = 0
    for i in $game_system.results
      countQVues += 1
      if(i[1][1].to_i > 0)
        rateRep += 1
      end
    end
    stat = "{\n"
    stat += "\"general\": "
    stat += "{"
    stat += "\"nom\": \"mickael\", "
    stat += "\"repTotales\": " + countQVues.to_s + ", "
    stat += "\"rateRep\": " + rateRep.to_s
    stat += "},\n"
    stat += "\"detail\": "
    stat += "["
    cpt = 0
    for i in $game_system.results
      stat += "{"
      stat += "\"id\": \"" + i[0].to_s + "\", "
      stat += "\"tentative\": " + i[1][0].to_s + ", "
      stat += "\"rate\": " + i[1][1].to_s
      if(cpt >= $game_system.results.length - 1)
        stat += "}"
      else
        stat += "},"
      end
      cpt += 1
    end
    stat.to_s.chop
    stat += "]\n"
    stat += "}"
    File.open("Stats/stats.json", 'w') { |file| file.write(stat) }
  end
  
  singleton_class.send(:alias_method, :original_call , :save_game_without_rescue)
  def self.save_game_without_rescue(index)
    statistiques
    return original_call(index)
    
  end
  
end

  #--------------------------------------------------------------------------
  # * Fais disparaitre le message au début du combat
  #--------------------------------------------------------------------------

module BattleManager
  
  def self.battle_start
    $game_system.battle_count += 1
    $game_party.on_battle_start
    $game_troop.on_battle_start
  end
  
end
