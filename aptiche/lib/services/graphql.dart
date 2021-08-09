import 'package:aptiche/utils/mutation.dart';
import 'package:aptiche/utils/query.dart';
import 'package:aptiche/datamodels/api_models.dart';
import 'package:aptiche/utils/string.dart';
import 'package:flutter/material.dart';
import 'package:graphql_flutter/graphql_flutter.dart';

class GraphQLService {
  /// Stores the [GraphQLClient]
  late GraphQLClient _client;

  /// Intialises the [GraphQLClient]
  Future<void> initGraphQL(String? token) async {
    final HttpLink _httpLink = HttpLink(Strings.GRAPHQL_URL);
    final AuthLink _authLink = AuthLink(getToken: () async => 'Bearer $token');

    final Link _link = _authLink.concat(_httpLink);
    _client = GraphQLClient(link: _link, cache: GraphQLCache());

    debugPrint('GraphQL initialised');
  }

  Future<void> getUser() async {
    final QueryOptions options = QueryOptions(
        document: gql(getUsers),
        variables: <String, List<String>>{'ids': <String>[]},
        pollInterval: const Duration(seconds: 10));

    final QueryResult result = await _client.query(options);

    if (result.hasException) {
      debugPrint(result.exception.toString());
    }
  }

  /// A graphql mutation that creates a user and stores the data in the
  /// database.
  Future<String?> createUsers({
    List<String?>? fcmTokens,
    String? name,
    String? email,
    String? phoneNo,
    String? rollNo,
    List<String?>? quizzes,
  }) async {
    final QueryResult result = await _client.mutate(
      MutationOptions(document: gql(createUser), variables: <String, dynamic>{
        'name': name,
        'email': email,
        'phoneNo': phoneNo,
        'rollNo': rollNo,
        'fcmToken': fcmTokens,
        'quizzes': quizzes
      }),
    );
    if (result.hasException) {
      debugPrint(result.exception.toString());
    }
    debugPrint(result.toString());
    return result.data!['createUser']['_id'].toString();
  }

  /// Takes any integer between 1-3 and queries the [GraphQL] server to get
  /// quizzes according the integer passed.
  /// `1 - Past Quizzes`
  /// `2 - Active Quizzes`
  /// `3 - Upcoming Quizzes`
  Future<List<Quiz>> getQuizzesByTime(int integer) async {
    final QueryOptions options = QueryOptions(
      document: gql(getQuizzesByTimeQuery),
      variables: <String, int>{'int': integer},
    );
    try {
      final QueryResult result = await _client.query(options);
      if (result.hasException) {
        debugPrint(result.exception.toString());
      }

      /// Takes in data from [QueryResult] and converts it to a map
      List<Map<String, dynamic>> toMap(Map<String, dynamic> data) {
        /// Stores the list of instruction strings.
        final List<String> instructionsList = <String>[];

        final List<Map<String, dynamic>> list = <Map<String, dynamic>>[];
        // Since graphql is returning everything as an object, each string in
        // the instructions list is first converted from an object to string
        // and then parsed into the map.
        for (final dynamic quiz in data['getQuizzesByTime']) {
          for (final dynamic instruction in quiz['instructions']) {
            instructionsList.add(instruction.toString());
          }
          final Map<String, dynamic> listItem = <String, dynamic>{
            '_id': quiz['_id'],
            'name': quiz['name'],
            'startTime': quiz['startTime'],
            'endTime': quiz['endTime'],
            'instructions': instructionsList,
            'active': quiz['active']
          };
          list.add(listItem);
        }
        return list;
      }

      final List<Map<String, dynamic>> getQuizzes = toMap(result.data!);

      /// Stores the final result i.e. all the quizzes.
      final List<Quiz> quizzes = <Quiz>[];

      /// Converts the map into a [Quiz] Object
      for (final Map<String, dynamic> quiz in getQuizzes) {
        final Quiz singleQuiz = Quiz.fromJson(quiz);
        quizzes.add(singleQuiz);
      }

      return quizzes;
    } catch (e) {
      rethrow;
    }
  }

  Future<List<Question>> getQuestionsByQuiz(List<String> ids) async {
    final QueryOptions options = QueryOptions(
        document: gql(getQuestionsByQuizQuery),
        variables: <String, List<String>>{'ids': ids});
    try {
      final QueryResult result = await _client.query(options);

      if (result.hasException) {
        debugPrint(result.exception.toString());
      }

      /// Takes in data from [QueryResult] and converts it to a map
      List<Map<String, dynamic>> toMap(Map<String, dynamic> data) {
        /// Stores the list of instruction strings.

        final List<Map<String, dynamic>> list = <Map<String, dynamic>>[];
        // Since graphql is returning everything as an object, each string in
        // the instructions list is first converted from an object to string
        // and then parsed into the map.
        for (final dynamic quiz in data['getQuestionsForQuiz']) {
          for (final dynamic question in quiz) {
            final List<String> options = <String>[];
            options.length = 0;

            for (final dynamic option in question['options']) {
              if (options.length < 4) {
                options.add(option.toString());
              }
            }

            final Map<String, dynamic> listItem = <String, dynamic>{
              '_id': question['_id'],
              'question': question['question'],
              'image': question['image'],
              'options': options,
              'answer': question['answer'],
              'positiveMark': question['positiveMark'],
              'negativeMark': question['negativeMark'],
              'explanation': question['explanation'],
            };
            list.add(listItem);
          }
        }
        return list;
      }

      final List<Map<String, dynamic>> getQuestionsByQuiz = toMap(result.data!);

      final List<Question> questions = <Question>[];

      for (final Map<String, dynamic> question in getQuestionsByQuiz) {
        final Question singleQuestion = Question.fromJson(question);
        questions.add(singleQuestion);
      }

      return questions;
    } catch (e) {
      rethrow;
    }
  }
}
