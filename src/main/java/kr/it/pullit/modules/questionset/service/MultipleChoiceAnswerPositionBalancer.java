package kr.it.pullit.modules.questionset.service;

import java.util.ArrayList;
import java.util.Collections;
import java.util.List;
import java.util.Objects;
import java.util.Random;
import kr.it.pullit.modules.questionset.client.dto.response.LlmGeneratedQuestionResponse;
import org.springframework.stereotype.Component;

@Component
public class MultipleChoiceAnswerPositionBalancer {

  private static final int OPTION_COUNT = 4;

  public List<LlmGeneratedQuestionResponse> balance(
      List<LlmGeneratedQuestionResponse> questions, long shuffleSeed) {
    Objects.requireNonNull(questions, "객관식 문제 목록은 null일 수 없습니다.");
    List<Integer> targetPositions = createBalancedTargetPositions(questions.size(), shuffleSeed);

    List<LlmGeneratedQuestionResponse> balancedQuestions = new ArrayList<>(questions.size());
    for (int index = 0; index < questions.size(); index++) {
      balancedQuestions.add(moveAnswerTo(questions.get(index), targetPositions.get(index)));
    }
    return List.copyOf(balancedQuestions);
  }

  private List<Integer> createBalancedTargetPositions(int questionCount, long shuffleSeed) {
    List<Integer> targetPositions = new ArrayList<>(questionCount);
    for (int index = 0; index < questionCount; index++) {
      targetPositions.add(index % OPTION_COUNT);
    }
    Collections.shuffle(targetPositions, new Random(shuffleSeed));
    return targetPositions;
  }

  private LlmGeneratedQuestionResponse moveAnswerTo(
      LlmGeneratedQuestionResponse question, int targetPosition) {
    List<String> options = requireValidOptions(question);
    int answerPosition = findUniqueAnswerPosition(options, question.answer());
    Collections.swap(options, answerPosition, targetPosition);

    return new LlmGeneratedQuestionResponse(
        question.id(),
        question.questionText(),
        List.copyOf(options),
        question.answer(),
        question.explanation());
  }

  private List<String> requireValidOptions(LlmGeneratedQuestionResponse question) {
    if (question.options() == null || question.options().size() != OPTION_COUNT) {
      throw new IllegalArgumentException("객관식 문제는 정확히 4개의 선지가 필요합니다.");
    }
    return new ArrayList<>(question.options());
  }

  private int findUniqueAnswerPosition(List<String> options, String answer) {
    if (answer == null || answer.isBlank()) {
      throw new IllegalArgumentException("객관식 정답은 비어 있을 수 없습니다.");
    }

    int answerPosition = -1;
    for (int index = 0; index < options.size(); index++) {
      if (!options.get(index).equals(answer)) {
        continue;
      }
      if (answerPosition >= 0) {
        throw new IllegalArgumentException("객관식 정답은 선지에 정확히 한 번만 포함되어야 합니다.");
      }
      answerPosition = index;
    }
    if (answerPosition < 0) {
      throw new IllegalArgumentException("객관식 정답이 선지에 포함되어 있지 않습니다.");
    }
    return answerPosition;
  }
}
