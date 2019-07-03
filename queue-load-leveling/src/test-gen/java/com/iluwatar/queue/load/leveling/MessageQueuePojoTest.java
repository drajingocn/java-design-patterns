package com.iluwatar.queue.load.leveling;

import com.aurea.unittest.commons.pojo.Testers;
import com.aurea.unittest.commons.pojo.chain.TestChain;
import com.openpojo.reflection.impl.PojoClassFactory;
import javax.annotation.Generated;
import org.junit.Test;

@Generated("GeneralPatterns")
public class MessageQueuePojoTest {

  @Test
  public void validateMessageQueueConstructors() {
    TestChain.startWith(Testers.constructorTester())
        .buildValidator()
        .validate(PojoClassFactory.getPojoClass(MessageQueue.class));
  }
}
