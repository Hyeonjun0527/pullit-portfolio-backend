package kr.it.pullit.modules.questionset.service;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;

import java.util.ArrayList;
import java.util.List;
import kr.it.pullit.modules.questionset.client.dto.response.LlmGeneratedQuestionResponse;
import kr.it.pullit.support.annotation.MockitoUnitTest;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;

@MockitoUnitTest
@DisplayName("객관식 정답 위치 균형 조정 단위 테스트")
class MultipleChoiceAnswerPositionBalancerTest {

  private final MultipleChoiceAnswerPositionBalancer balancer =
      new MultipleChoiceAnswerPositionBalancer();

  @Test
  @DisplayName("정답 위치를 1번부터 4번까지 최대 한 문제 차이로 배치한다")
  void balancesAnswerPositionsAcrossAllFourOptions() {
    List<LlmGeneratedQuestionResponse> questions = createQuestions(10);

    List<LlmGeneratedQuestionResponse> balanced = balancer.balance(questions, 3L);

    int[] counts = countAnswerPositions(balanced);
    assertThat(counts).containsExactlyInAnyOrder(3, 3, 2, 2);
  }

  @Test
  @DisplayName("원본 LLM 응답의 선지 순서는 변경하지 않는다")
  void doesNotMutateOriginalQuestions() {
    List<LlmGeneratedQuestionResponse> questions = createQuestions(4);
    List<String> originalOptions = List.copyOf(questions.getFirst().options());

    balancer.balance(questions, 1L);

    assertThat(questions.getFirst().options()).containsExactlyElementsOf(originalOptions);
  }

  @Test
  @DisplayName("정답이 선지에 없으면 즉시 실패한다")
  void rejectsAnswerMissingFromOptions() {
    var invalid = question(1, List.of("오답1", "오답2", "오답3", "오답4"), "정답");

    assertThatThrownBy(() -> balancer.balance(List.of(invalid), 1L))
        .isInstanceOf(IllegalArgumentException.class)
        .hasMessage("객관식 정답이 선지에 포함되어 있지 않습니다.");
  }

  @Test
  @DisplayName("정답이 선지에 중복되면 즉시 실패한다")
  void rejectsDuplicatedAnswer() {
    var invalid = question(1, List.of("정답", "오답1", "정답", "오답2"), "정답");

    assertThatThrownBy(() -> balancer.balance(List.of(invalid), 1L))
        .isInstanceOf(IllegalArgumentException.class)
        .hasMessage("객관식 정답은 선지에 정확히 한 번만 포함되어야 합니다.");
  }

  @Test
  @DisplayName("선지가 네 개가 아니면 즉시 실패한다")
  void rejectsUnexpectedOptionCount() {
    var invalid = question(1, List.of("정답", "오답1", "오답2"), "정답");

    assertThatThrownBy(() -> balancer.balance(List.of(invalid), 1L))
        .isInstanceOf(IllegalArgumentException.class)
        .hasMessage("객관식 문제는 정확히 4개의 선지가 필요합니다.");
  }

  @Test
  @DisplayName("정답이 비어 있으면 즉시 실패한다")
  void rejectsBlankAnswer() {
    var invalid = question(1, List.of("보기1", "보기2", "보기3", "보기4"), " ");

    assertThatThrownBy(() -> balancer.balance(List.of(invalid), 1L))
        .isInstanceOf(IllegalArgumentException.class)
        .hasMessage("객관식 정답은 비어 있을 수 없습니다.");
  }

  private List<LlmGeneratedQuestionResponse> createQuestions(int count) {
    List<LlmGeneratedQuestionResponse> questions = new ArrayList<>(count);
    for (int index = 1; index <= count; index++) {
      questions.add(question(index, List.of("오답1", "정답", "오답2", "오답3"), "정답"));
    }
    return questions;
  }

  private LlmGeneratedQuestionResponse question(int id, List<String> options, String answer) {
    return new LlmGeneratedQuestionResponse(id, "문제 " + id, options, answer, "해설 " + id);
  }

  private int[] countAnswerPositions(List<LlmGeneratedQuestionResponse> questions) {
    int[] counts = new int[4];
    for (LlmGeneratedQuestionResponse question : questions) {
      counts[question.options().indexOf(question.answer())]++;
    }
    return counts;
  }
}
